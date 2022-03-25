import 'package:flutter/material.dart';

ScaffoldFeatureController showMessage(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 1),
}) {
  final width = MediaQuery.of(context).size.width;
  return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: duration,
    behavior: SnackBarBehavior.floating,
    width: width < 540 ? null : 400,
  ));
}
