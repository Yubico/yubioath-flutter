import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScannedData {
  final String data;
  final Rect location;

  ScannedData(this.data, this.location);
}

class QrScannerMLKitView extends StatefulWidget {
  final Function(ScannedData data) onDetect;
  const QrScannerMLKitView({Key? key, required this.onDetect})
      : super(key: key);

  @override
  QrScannerMLKitViewState createState() => QrScannerMLKitViewState();
}

class QrScannerMLKitViewState extends State<QrScannerMLKitView> {
  final MethodChannel channel = const MethodChannel(
      "com.yubico.authenticator.flutter_plugins.qr_scanner_channel");

  QrScannerMLKitViewState() : super() {
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
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
