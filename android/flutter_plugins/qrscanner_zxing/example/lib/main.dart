import 'package:flutter/material.dart';
import 'package:qrscanner_zxing/qrscanner_zxing_view.dart';

import 'cutout_overlay.dart';

void main() {
  runApp(const QRCodeScannerExampleApp());
}

class QRCodeScannerExampleApp extends StatelessWidget {
  const QRCodeScannerExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scanner Example',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const AppHomePage(title: 'QR Scanner Example'),
    );
  }
}

class AppHomePage extends StatelessWidget {
  const AppHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const QRScannerPage(),
                        transitionDuration: const Duration(seconds: 0),
                        reverseTransitionDuration: const Duration(seconds: 0),
                      ));
                },
                child: const Text("Open QR Scanner")),
          ],
        ),
      ),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  QRScannerPageState createState() => QRScannerPageState();
}

class QRScannerPageState extends State<QRScannerPage> {
  String? currentCode;

  QRScannerPageState({Key? key}) : super();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: QRScannerZxingView(
                marginPct: 10,
                onDetect: (result) {
                  if (currentCode == null) {
                    setState(() {
                      currentCode = result;
                    });
                  }
                })),
        const Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: CutoutOverlay(
              marginPct: 5,
            )),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Back'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Again"),
                  onPressed: () {
                    setState(() {
                      currentCode = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Card(
              margin: const EdgeInsets.all(20),
              elevation: 100,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("Found QR code:"),
                    Text(currentCode ?? "NO CODE DETECTED"),
                  ],
                ),
              )),
        ),
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Card(
              margin: const EdgeInsets.all(20),
              elevation: 100,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Text("QR scanner example"),
                  ],
                ),
              )),
        )
      ],
    ));
  }
}
