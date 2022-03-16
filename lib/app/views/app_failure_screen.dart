import 'package:flutter/material.dart';

class AppFailureScreen extends StatelessWidget {
  final String reason;
  const AppFailureScreen(this.reason, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            reason,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
