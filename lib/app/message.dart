import 'package:flutter/material.dart';

ScaffoldFeatureController showMessage(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 1),
}) {
  final width = MediaQuery.of(context).size.width;
  final narrow = width < 540;
  return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: duration,
    behavior: narrow ? SnackBarBehavior.fixed : SnackBarBehavior.floating,
    width: narrow ? null : 400,
  ));
}
