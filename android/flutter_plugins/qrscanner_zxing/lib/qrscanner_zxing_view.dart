import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class QRScannerZxingView extends StatefulWidget {
  final int marginPct;
  final Function(String rawData) onDetect;
  final Function(bool permissionsGranted) onViewInitialized;

  const QRScannerZxingView(
      {Key? key,
      required this.marginPct,
      required this.onDetect,
      required this.onViewInitialized})
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
        switch (call.method) {
          case "codeFound":
            var arguments = jsonDecode(call.arguments);
            var rawValue = arguments["value"];
            widget.onDetect(rawValue);
            return;
          case "viewInitialized":
            var arguments = jsonDecode(call.arguments);
            var permissionsGranted = arguments["permissionsGranted"];
            widget.onViewInitialized(permissionsGranted);
            return;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint("Exception in onDetect: $e}");
        }
      }
    });
  }

  void requestPermissions() {
    debugPrint("Permissions requested");
    channel.invokeMethod("requestCameraPermissions", null);
  }

  @override
  void dispose() {
    super.dispose();
    channel.setMethodCallHandler(null);
  }

  @override
  Widget build(BuildContext context) {
    const String viewType = 'qrScannerNativeView';
    Map<String, dynamic> creationParams = <String, dynamic>{
      "margin": widget.marginPct
    };
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
        });
  }
}
