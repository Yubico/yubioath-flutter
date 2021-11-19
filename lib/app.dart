import 'package:flutter/material.dart';

class YubicoAuthenticatorApp extends StatelessWidget {
  final Widget page;
  const YubicoAuthenticatorApp({required this.page, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yubico Authenticator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: page,
    );
  }
}
