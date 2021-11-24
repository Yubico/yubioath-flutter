import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:async/async.dart';

import 'models.dart';

final log = Logger('rpc');

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
            .map((event) => RpcResponse.fromJson(jsonDecode(event)))) {
    _process.stderr
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .map((event) => jsonDecode(event))
        .listen((event) {
      Logger('rpc.${event['name']}').log(
        _py2level[event['level']] ?? Level.INFO,
        event['message'],
        //time: DateTime.fromMillisecondsSinceEpoch(event['time'] * 1000),
      );
    });
    log.info('Launched ykman subprocess...');
    _pump();
  }

  static Future<RpcSession> launch(String executable) async {
    var process =
        await Process.start(executable, [], environment: {'_YKMAN_RPC': '1'});
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
    if (level.value <= Level.CONFIG.value) {
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
    log.fine('SEND', jsonEncode(data));
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
        log.fine('RECV', jsonEncode(response));
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
