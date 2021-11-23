import 'package:flutter/material.dart';

class NoDeviceScreen extends StatelessWidget {
  const NoDeviceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('Insert a YubiKey'),
        ],
      ),
    );
  }
}
