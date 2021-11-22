import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:async/async.dart';

import 'models.dart';

class Signaler {
  final _controller = StreamController<Signal>();
  void Function(String)? _sendSignal;

  Stream<Signal> get signals => _controller.stream;

  void cancel() {
    final sendSignal = _sendSignal;
    if (sendSignal == null) {
      throw Exception('Signaler not attached to any request!');
    }
    sendSignal('cancel');
  }
}

class _Request {
  final String action;
  final List<String> target;
  final Map body;
  final Signaler? signal;
  final List<String> signals = [];
  final Completer<Map<String, dynamic>> completer = Completer();

  _Request(this.action, this.target, this.body, this.signal) {
    signal?._sendSignal = signals.add;
  }

  Map<String, dynamic> toJson() => {
        'kind': 'command',
        'action': action,
        'target': target,
        'body': body,
      };
}

class RpcSession {
  final Process _process;
  final StreamController<_Request> _requests = StreamController();
  final StreamQueue<RpcResponse> _responses;

  RpcSession(this._process)
      : _responses = StreamQueue(_process.stdout
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())
            .map((event) => RpcResponse.fromJson(jsonDecode(event)))) {
    stderr.addStream(_process.stderr);
    developer.log('Launched ykman subprocess...', name: 'rpc');
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

  void _send(Map data) {
    developer.log('SEND', name: 'rpc', error: jsonEncode(data));
    _process.stdin.writeln(jsonEncode(data));
    _process.stdin.flush();
  }

  void _pump() async {
    await for (final request in _requests.stream) {
      _send(request.toJson());

      sendSignal(status) {
        _send({'kind': 'signal', 'status': status});
      }

      request.signals.forEach(sendSignal);
      request.signal?._sendSignal = sendSignal;

      bool done = false;
      while (!done) {
        final response = await _responses.next;
        developer.log('RECV', name: 'rpc', error: jsonEncode(response));
        response.map(
          signal: (signal) {
            request.signal?._controller.sink.add(signal);
          },
          success: (success) {
            request.completer.complete(success.body);
            done = true;
          },
          error: (error) {
            request.completer.completeError(error);
            done = true;
          },
        );
      }

      request.signal?._sendSignal = null;
      request.signal?._controller.close();
    }
  }
}
