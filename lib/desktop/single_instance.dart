import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

const _lockFileName = 'lockfile';
const _pingMessage = 'YA-PING';
const _pongMessage = 'YA-PONG';

final log = Logger('single_instance');

void _startServer(File lockfile) async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  lockfile.writeAsString('${socket.port}');

  log.info('Lock file and socket created.');
  socket.listen((client) {
    client.listen((data) async {
      final message = String.fromCharCodes(data);
      if (message == _pingMessage) {
        log.info('Got incomming connection');

        if (!await WindowManager.instance.isMinimized()) {
          // Causes the window to be brought to the front.
          await WindowManager.instance.setAlwaysOnTop(true);
          await WindowManager.instance.setAlwaysOnTop(false);
        } else {
          await WindowManager.instance.restore();
        }

        // This doesn't seem to always work
        await WindowManager.instance.focus();
        client.write(_pongMessage);
      }
      client.close();
    }, cancelOnError: true);
  });
}

Future<void> ensureSingleInstance() async {
  final appSupport = await getApplicationSupportDirectory();
  final lockfile = File(path.join(appSupport.path, _lockFileName));
  log.info('Lock file: $lockfile');

  if (await lockfile.exists()) {
    try {
      final port = int.parse(await lockfile.readAsString());
      final client = await Socket.connect(InternetAddress.loopbackIPv4, port);
      client.write(_pingMessage);
      client.listen((data) async {
        final message = String.fromCharCodes(data);
        await client.close();
        if (message == _pongMessage) {
          log.info('Other application instance already running, exit.');
          exit(0);
        }
      }, cancelOnError: true);
    } on Exception {
      // No server listening on the port, or bad data in the file
      await lockfile.delete();
      _startServer(lockfile);
    }
  } else {
    _startServer(lockfile);
  }
}
