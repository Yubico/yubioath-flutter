import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

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
  final Completer<Map<String, dynamic>> completer = Completer();
  final Signaler? signal;

  _Request(this.action, this.target, this.body, this.signal);

  Map<String, dynamic> toJson() => {
        'kind': 'command',
        'action': action,
        'target': target,
        'body': body,
      };
}

class RpcSession {
  final Process _process;
  final StreamSubscription<Map<String, dynamic>> responses;
  final Queue<_Request> _requests = Queue();
  bool _busy = false;

  RpcSession(this._process)
      : responses = _process.stdout
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())
            .map((event) => jsonDecode(event))
            .cast<Map<String, dynamic>>()
            .listen(null) {
    stderr.addStream(_process.stderr);
    developer.log('Launched ykman subprocess...', name: 'rpc');
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
    pump();

    return request.completer.future;
  }

  void pump() {
    if (!_busy && _requests.isNotEmpty) {
      final request = _requests.removeFirst();
      _busy = true;
      request.signal?._sendSignal = _sendSignal;

      responses.onData((data) {
        developer.log('RECV', name: 'rpc', error: jsonEncode(data));
        try {
          final response = RpcResponse.fromJson(data);
          if (response.map(
            signal: (signal) {
              request.signal?._controller.sink.add(signal);
              return false;
            },
            success: (success) {
              request.completer.complete(success.body);
              return true;
            },
            error: (error) {
              request.completer.completeError(error);
              return true;
            },
          )) {
            responses.onData(null);
            request.signal?._sendSignal = null;
            request.signal?._controller.close();
            _busy = false;
            pump();
          }
        } catch (e) {
          developer.log('Invalid RPC message',
              name: 'rpc', error: jsonEncode(e));
        }
      });

      _send(request.toJson());
    }
  }

  void _sendSignal(String status) {
    _send({'kind': 'signal', 'status': status});
  }

  void _send(Map data) {
    developer.log('SEND', name: 'rpc', error: jsonEncode(data));
    _process.stdin.writeln(jsonEncode(data));
    _process.stdin.flush();
  }
}
