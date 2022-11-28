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
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:async/async.dart';
import 'package:yubico_authenticator/app/logging.dart';

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
      : _responses = StreamQueue(stream.map((event) {
          try {
            return RpcResponse.fromJson(jsonDecode(event));
          } catch (e) {
            _log.error('Response was not valid JSON', event);
            return RpcResponse.error('invalid-response', e.toString(), {});
          }
        }));

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

  RpcSession(this.executable);

  static void _logEntry(String entry) {
    try {
      final record = jsonDecode(entry);
      var entryLevel = _py2level[record['level']];
      if (entryLevel == null) {
        Logger('helper.${record['name']}')
            .log(Levels.ERROR, 'Invalid log level: ${record['level']}');
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

  Future<bool> elevate() async {
    if (!Platform.isWindows) {
      throw Exception('Elevate is only available for Windows');
    }

    final random = Random.secure();
    final nonce = base64Encode(List.generate(32, (_) => random.nextInt(256)));

    // Bind to random port
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    _log.debug('Listening for Helper connection on $port');

    // Launch the elevated process
    final process =
        await Process.start('powershell.exe', ['-NoProfile', '-Command', '-']);

    _log.info('Attempting to elevate $executable');
    process.stdin.writeln(
        'Start-Process "$executable" -Verb runAs -WindowStyle hidden -ArgumentList "--tcp $port $nonce"');
    await process.stdin.flush();
    await process.stdin.close();
    if (await process.exitCode != 0) {
      await server.close();
      final error = await process.stderr
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .join('\n');
      _log.warning('Failed to elevate the Helper process', error);
      return false;
    }
    _log.debug('Elevated Helper process started');

    // Accept only a single connection
    final client = await server.first;
    await server.close();
    _log.debug('Helper connected: $client');

    // Stop the old subprocess.
    try {
      await command('quit', []);
    } catch (error) {
      _log.warning('Failed to dispose existing process', error);
    }

    bool authenticated = false;
    final completer = Completer<void>();
    final read =
        utf8.decoder.bind(client).transform(const LineSplitter()).map((line) {
      // The nonce needs to be received first.
      if (!authenticated) {
        if (nonce == line) {
          _log.debug('Helper authenticated with correct nonce');
          authenticated = true;
          completer.complete();
          return '';
        } else {
          _log.warning('Helper used WRONG NONCE: $line');
          client.close();
          completer.completeError(Exception('Invalid nonce'));
          throw Exception('Invalid nonce');
        }
      } else {
        // Filter out (and log) log messages
        final type = line[0];
        final message = line.substring(1);
        switch (type) {
          case 'O':
            return message;
          case 'E':
            _logEntry(message);
            return '';
          default:
            _log.error('Invalid message: $line');
            throw Exception('Invalid message type: $type');
        }
      }
    }).where((line) => line.isNotEmpty);
    _connection = _RpcConnection(client, read);

    await completer.future;
    return true;
  }

  Future<Map<String, dynamic>> command(String action, List<String>? target,
      {Map? params, Signaler? signal}) {
    var request = _Request(action, target ?? [], params ?? {}, signal);
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
        response.map(
          signal: (signal) {
            final signaler = request.signal;
            if (signaler != null) {
              signaler._recv.sink.add(signal);
            } else {
              _log.warning('Received unhandled signal: $signal');
            }
          },
          success: (success) {
            request.completer.complete(success.body);
            completed = true;
          },
          error: (error) {
            request.completer.completeError(error);
            completed = true;
          },
        );
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
