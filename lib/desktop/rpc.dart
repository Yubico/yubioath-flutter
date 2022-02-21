import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:async/async.dart';

import '../app/models.dart';
import 'models.dart';

final _log = Logger('rpc');

class Signaler {
  final _send = StreamController<String>();
  final _recv = StreamController<Signal>();

  Stream<Signal> get signals => _recv.stream;

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
  'DEBUG': Level.CONFIG,
  'INFO': Level.INFO,
  'WARNING': Level.WARNING,
  'ERROR': Level.SEVERE,
  'CRITICAL': Level.SHOUT,
};

class RpcSession {
  final Process _process;
  final StreamController<_Request> _requests = StreamController();
  final StreamQueue<RpcResponse> _responses;

  RpcSession(this._process)
      : _responses = StreamQueue(_process.stdout
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())
            .map((event) {
          try {
            return RpcResponse.fromJson(jsonDecode(event));
          } catch (e) {
            _log.severe('Response was not valid JSON', event);
            return RpcResponse.error('invalid-response', e.toString(), {});
          }
        })) {
    _process.stderr
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .map((event) => jsonDecode(event))
        .listen((event) {
      Logger('rpc.${event['name']}').log(
        _py2level[event['level']] ?? Level.INFO,
        event['message'],
        event['exc_text'],
        //time: DateTime.fromMillisecondsSinceEpoch(event['time'] * 1000),
      );
    }, onError: (err) {
      Logger('rpc.error').log(
        Level.SEVERE,
        err.toString(),
      );
    });
    _log.info('Launched ykman subprocess...');
    _pump();
  }

  static Future<RpcSession> launch(String executable) async {
    var process = await Process.start(executable, []);
    return RpcSession(process);
  }

  Future<Map<String, dynamic>> command(String action, List<String>? target,
      {Map? params, Signaler? signal}) {
    var request = _Request(action, target ?? [], params ?? {}, signal);
    _requests.add(request);
    return request.completer.future;
  }

  setLogLevel(Level level) {
    String pyLevel;
    if (level.value <= Level.FINE.value) {
      pyLevel = 'traffic';
    } else if (level.value <= Level.CONFIG.value) {
      pyLevel = 'debug';
    } else if (level.value <= Level.INFO.value) {
      pyLevel = 'info';
    } else if (level.value <= Level.WARNING.value) {
      pyLevel = 'warning';
    } else if (level.value <= Level.SEVERE.value) {
      pyLevel = 'error';
    } else {
      pyLevel = 'critical';
    }
    command('logging', [], params: {'level': pyLevel});
  }

  void _send(Map data) {
    _log.fine('SEND', jsonEncode(data));
    _process.stdin.writeln(jsonEncode(data));
    _process.stdin.flush();
  }

  void _pump() async {
    await for (final request in _requests.stream) {
      _send(request.toJson());

      request.signal?._send.stream.listen((status) {
        _send({'kind': 'signal', 'status': status});
      });

      bool completed = false;
      while (!completed) {
        final response = await _responses.next;
        _log.fine('RECV', jsonEncode(response));
        response.map(
          signal: (signal) {
            request.signal?._recv.sink.add(signal);
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

      request.signal?._close();
    }
  }
}

typedef ErrorHandler = Future<void> Function(RpcError e);

class RpcNodeSession {
  final RpcSession _rpc;
  final DevicePath devicePath;
  final List<String> subPath;
  final Map<String, ErrorHandler> _errorHandlers = {};

  RpcNodeSession(this._rpc, this.devicePath, this.subPath);

  void setErrorHandler(String status, ErrorHandler handler) {
    _errorHandlers[status] = handler;
  }

  void unserErrorHandler(String status) {
    _errorHandlers.remove(status);
  }

  Future<Map<String, dynamic>> command(
    String action, {
    List<String> target = const [],
    Map<dynamic, dynamic>? params,
    Signaler? signal,
  }) async {
    try {
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
        return command(action, target: target, params: params, signal: signal);
      }
      rethrow;
    }
  }
}
