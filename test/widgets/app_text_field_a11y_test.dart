import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yubico_authenticator/widgets/app_text_field.dart';

void main() {
  testWidgets('AppTextField live-region updates on caret move right', (
    tester,
  ) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    final semantics = tester.ensureSemantics();
    try {
      final controller = TextEditingController(text: 'abc')
        ..selection = const TextSelection.collapsed(offset: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(controller: controller).init(),
          ),
        ),
      );

      controller.selection = const TextSelection.collapsed(offset: 1);
      await tester.pump();

      expect(find.bySemanticsLabel('b\u200B'), findsAtLeastNWidgets(1));
    } finally {
      semantics.dispose();
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });

  testWidgets('AppTextField live-region updates on caret move left', (
    tester,
  ) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    final semantics = tester.ensureSemantics();
    try {
      final controller = TextEditingController(text: 'abc')
        ..selection = const TextSelection.collapsed(offset: 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(controller: controller).init(),
          ),
        ),
      );

      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      expect(find.bySemanticsLabel('c\u200B'), findsAtLeastNWidgets(1));
    } finally {
      semantics.dispose();
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });
}
