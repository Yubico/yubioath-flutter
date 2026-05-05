/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:logging/logging.dart';

import '../app/logging.dart';
import '../app/models.dart';
import 'models.dart';

final _log = Logger('helper');

class Signaler {
  final _send = StreamController<String>();
  final _recv = StreamController<Signal>();

  Stream<Signal> get signals => _recv.stream;

  Stream<String> get _sendStream => _send.stream;

  void cancel() {
    _send.add('cancel');
  }

  void _close() {
    _send.close();
    _recv.close();
  }
}

class _Request {
  final String action;
  final List<String> target;
  final Map body;
  final Signaler? signal;
  final Completer<Map<String, dynamic>> completer = Completer();

  _Request(this.action, this.target, this.body, this.signal);

  Map<String, dynamic> toJson() => {
    'kind': 'command',
    'action': action,
    'target': target,
    'body': body,
  };
}

const _py2level = {
  'TRAFFIC': Level.FINE,
  'DEBUG': Level.CONFIG,
  'INFO': Level.INFO,
  'WARNING': Level.WARNING,
  'ERROR': Level.SEVERE,
  'CRITICAL': Level.SHOUT,
};

class _RpcConnection {
  final IOSink _sink;
  final StreamQueue<RpcResponse> _responses;
  _RpcConnection(this._sink, Stream<String> stream)
    : _responses = StreamQueue(
        stream.map((event) {
          try {
            return RpcResponse.fromJson(jsonDecode(event));
          } catch (e) {
            _log.error('Response was not valid JSON', event);
            return RpcResponse.error('invalid-response', e.toString(), {});
          }
        }),
      );

  void send(Map data) {
    _sink.writeln(jsonEncode(data));
  }

  Future<RpcResponse> getResponse() => _responses.next;

  Future<void> close() async {
    _sink.writeln('');
    await _responses.cancel();
    await _sink.close();
  }
}

class RpcSession {
  final String executable;
  late _RpcConnection _connection;
  final StreamController<_Request> _requests = StreamController();
  final StreamController<String> _flags = StreamController();
  late final Stream<String> flags;

  RpcSession(this.executable) {
    flags = _flags.stream.asBroadcastStream();
  }

  static void _logEntry(String entry) {
    try {
      final record = jsonDecode(entry);
      var entryLevel = _py2level[record['level']];
      if (entryLevel == null) {
        Logger(
          'helper.${record['name']}',
        ).log(Levels.ERROR, 'Invalid log level: ${record['level']}');
      } else {
        Logger('helper.${record['name']}').log(
          entryLevel,
          record['message'],
          record['exc_text'],
          //time: DateTime.fromMillisecondsSinceEpoch(event['time'] * 1000),
        );
      }
    } catch (e) {
      _log.error(entry);
    }
  }

  Future<void> initialize() async {
    final process = await Process.start(executable, []);
    _log.debug('Helper process started');
    process.stderr
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(_logEntry);

    // Communicate with rpc over stdin/stdout.
    _connection = _RpcConnection(
      process.stdin,
      process.stdout
          .transform(const Utf8Decoder())
          .transform(const LineSplitter()),
    );

    _pump();
  }

  Future<Map<String, dynamic>> command(
    String action,
    List<String>? target, {
    Map? params,
    Signaler? signal,
  }) {
    final request = _Request(action, target ?? [], params ?? {}, signal);
    _requests.add(request);
    return request.completer.future;
  }

  Future<void> setLogLevel(Level level) async {
    final name = Levels.LEVELS
        .firstWhere((e) => level.value <= e.value, orElse: () => Level.OFF)
        .name
        .toLowerCase();

    await command('logging', [], params: {'level': name});
  }

  void _send(Map data) {
    _log.traffic('SEND', jsonEncode(data));
    _connection.send(data);
  }

  void _pump() async {
    await for (final request in _requests.stream) {
      if (request.action == 'quit') {
        await _connection.close();
        request.completer.complete({});
        continue;
      }

      _send(request.toJson());

      final signalSubscription = request.signal?._sendStream.listen((status) {
        _send({'kind': 'signal', 'status': status});
      });

      bool completed = false;
      while (!completed) {
        final response = await _connection.getResponse();
        _log.traffic('RECV', jsonEncode(response));
        switch (response) {
          case Signal():
            {
              final signaler = request.signal;
              if (signaler != null) {
                signaler._recv.sink.add(response);
              } else {
                _log.warning('Received unhandled signal: $response');
              }
            }
          case Success(:final body, :final flags):
            {
              request.completer.complete(body);
              for (final flag in flags) {
                _log.traffic('FLAG', flag);
                _flags.add(flag);
              }
              completed = true;
            }
          case RpcError():
            {
              request.completer.completeError(response);
              completed = true;
            }
        }
      }

      await signalSubscription?.cancel();
      request.signal?._close();
    }
  }
}

typedef ErrorHandler = Future<void> Function(RpcError e);

class _MultiSignaler extends Signaler {
  final Signaler delegate;
  @override
  final Stream<String> _sendStream;

  _MultiSignaler(this.delegate)
    : _sendStream = delegate._send.stream.asBroadcastStream() {
    signals.listen(delegate._recv.sink.add);
  }

  @override
  void _close() {}

  void _reallyClose() {
    super._close();
  }
}

class RpcNodeSession {
  final RpcSession _rpc;
  final DevicePath devicePath;
  final List<String> subPath;
  final Map<String, ErrorHandler> _errorHandlers = {};

  RpcNodeSession(this._rpc, this.devicePath, this.subPath);

  void setErrorHandler(String status, ErrorHandler handler) {
    _errorHandlers[status] = handler;
  }

  void unsetErrorHandler(String status) {
    _errorHandlers.remove(status);
  }

  Future<Map<String, dynamic>> command(
    String action, {
    List<String> target = const [],
    Map<dynamic, dynamic>? params,
    Signaler? signal,
  }) async {
    bool wrapped = false;
    try {
      if (signal != null && signal is! _MultiSignaler) {
        signal = _MultiSignaler(signal);
        wrapped = true;
      }
      return await _rpc.command(
        action,
        devicePath.segments + subPath + target,
        params: params,
        signal: signal,
      );
    } on RpcError catch (e) {
      final handler = _errorHandlers[e.status];
      if (handler != null) {
        _log.info('Attempting recovery on "${e.status}"');
        await handler(e);
        return await command(
          action,
          target: target,
          params: params,
          signal: signal,
        );
      }
      rethrow;
    } finally {
      if (wrapped) {
        (signal as _MultiSignaler)._reallyClose();
      }
    }
  }
}
