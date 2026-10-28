// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:lint/main.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseRecommendedWidgetTest);
    defineReflectiveTests(CallInitAfterCreationTest);
  });
}

@reflectiveTest
class UseRecommendedWidgetTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseRecommendedWidget();
    super.setUp();
  }

  void test_textField() async {
    const source = '''
class TextField {
  TextField();
}
void f() {
  TextField();
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('TextField();'), 'TextField'.length),
    ]);
  }

  void test_otherWidget() async {
    await assertNoDiagnostics('''
class OtherWidget {
  OtherWidget();
}
void f() {
  OtherWidget();
}
''');
  }
}

@reflectiveTest
class CallInitAfterCreationTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = CallInitAfterCreation();
    super.setUp();
  }

  void test_missingInit() async {
    const source = '''
class AppTextField {
  AppTextField();
  void init() {}
}
void f() {
  AppTextField();
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('AppTextField();'), 'AppTextField'.length),
    ]);
  }

  void test_callsInit() async {
    await assertNoDiagnostics('''
class AppTextField {
  AppTextField();
  void init() {}
}
void f() {
  AppTextField().init();
}
''');
  }
}
