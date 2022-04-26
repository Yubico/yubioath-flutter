import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class ScannedData {
  final String data;
  final Rect location;

  ScannedData(this.data, this.location);
}

class QRScannerZxingView extends StatefulWidget {
  final Function(ScannedData data) onDetect;

  const QRScannerZxingView({Key? key, required this.onDetect})
      : super(key: key);

  @override
  QRScannerZxingViewState createState() => QRScannerZxingViewState();
}

class QRScannerZxingViewState extends State<QRScannerZxingView> {
  final MethodChannel channel = const MethodChannel(
      "com.yubico.authenticator.flutter_plugins.qr_scanner_channel");

  QRScannerZxingViewState() : super() {
    channel.setMethodCallHandler((call) async {
      try {
        var barcodes = jsonDecode(call.arguments);
        if (barcodes is List && barcodes.isNotEmpty) {
          var firstBarcode = barcodes[0];
          var rawValue = firstBarcode["value"];
          var location = firstBarcode["location"];
          double l = location[0].toDouble();
          double t = location[1].toDouble();
          double r = location[2].toDouble();
          double b = location[3].toDouble();
          var locationRect = Rect.fromLTRB(l, t, r, b);
          widget.onDetect(ScannedData(rawValue, locationRect));
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint("Exception in onDetect: $e}");
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    channel.setMethodCallHandler(null);
  }

  @override
  Widget build(BuildContext context) {
    const String viewType = 'qrScannerNativeView';
    const Map<String, dynamic> creationParams = <String, dynamic>{};

    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory:
          (BuildContext context, PlatformViewController controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () {
            params.onFocusChanged(true);
          },
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }
}