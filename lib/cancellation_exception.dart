import 'package:flutter/services.dart';

class CancellationException implements Exception {
  CancellationException();

  static isCancellation(PlatformException pe) =>
    pe.code == 'CancellationException';

}
