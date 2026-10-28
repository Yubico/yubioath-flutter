import 'dart:async';
import 'dart:io';

const _controllerUrl = String.fromEnvironment('CONTROLLER');
const _picoPort = int.fromEnvironment('PICO_PORT', defaultValue: 6);

final picoController = _controllerUrl.isEmpty
    ? null
    : PicoController(_controllerUrl, _picoPort);

class PicoController {
  final Uri baseUrl;
  final int port;

  PicoController(String url, this.port) : baseUrl = Uri.parse(url);

  Future<void> _get(String path) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    final uri = baseUrl.resolve('/usb$port/$path');
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      await response.drain<void>().timeout(const Duration(seconds: 5));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Pico request failed: ${response.statusCode}',
          uri: uri,
        );
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> touch() async {
    await release();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _get('touch/on');
  }

  Future<void> release() => _get('touch/off');

  Future<void> remove() async {
    await release();
    await _get('power/off');
  }

  Future<void> insert() async {
    await _get('power/on');
    await Future<void>.delayed(const Duration(seconds: 2));
  }
}
