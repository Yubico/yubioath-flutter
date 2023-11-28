/*
 * Copyright (C) 2023 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

PluginBase createPlugin() => _AppLinter();

class _AppLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        UseRecommendedWidget(
          ruleName: 'use_recommended_app_text_field',
          import: 'widgets/app_text_field.dart',
          discouraged: 'TextField',
          recommended: 'AppTextField',
        ),
        UseRecommendedWidget(
          ruleName: 'use_recommended_app_text_form_field',
          import: 'widgets/app_text_form_field.dart',
          discouraged: 'TextFormField',
          recommended: 'AppTextFormField',
        ),
      ];
}

/// recommend to use App Widgets
class UseRecommendedWidget extends DartLintRule {
  final String ruleName;
  final String import;
  final String discouraged;
  final String recommended;

  UseRecommendedWidget({
    required this.ruleName,
    required this.import,
    required this.discouraged,
    required this.recommended,
  }) : super(
          code: LintCode(
              name: ruleName,
              problemMessage: 'Don\'t use $discouraged.',
              correctionMessage: 'Use $recommended',
              errorSeverity: ErrorSeverity.WARNING),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.constructorName.type.name2.lexeme == discouraged) {
        reporter.reportErrorForNode(code, node.constructorName);
      }
    });
  }

  @override
  List<Fix> getFixes() =>
      [_UseRecommendedFix(import, discouraged, recommended)];
}

class _UseRecommendedFix extends DartFix {
  final String import;
  final String discouraged;
  final String recommended;

  _UseRecommendedFix(this.import, this.discouraged, this.recommended);

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (analysisError.sourceRange != node.constructorName.sourceRange) {
        return;
      }

      print(
          'Added addInstanceCreationExpression for ${node.constructorName} @ ${node.sourceRange}');

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Change to $recommended.',
        priority: 0,
      );

      changeBuilder.addDartFileEdit((builder) async {
        print(
            'Executed dartFileEdit for ${node.constructorName} @ ${node.sourceRange}');
        Uri? importUri = null;
        final projectRoot = await _findProjectRoot(resolver.path);
        if (projectRoot != null) {
          final absoluteImportPath = p.join(projectRoot, import);
          final sourceFilePath = File(resolver.path).parent.path;

          // compute the relative path from our source code to the import
          String relativeImportPath =
              p.relative(absoluteImportPath, from: sourceFilePath);

          importUri = Uri(path: relativeImportPath);
        }

        builder.addSimpleReplacement(
          SourceRange(analysisError.offset, analysisError.length),
          recommended,
        );

        if (importUri != null && !builder.importsLibrary(importUri)) {
          print('$importUri is not yet imported');
          print('Required imports: ${builder.requiredImports}');
          builder.importLibraryElement(importUri);
        }
      });
    });
  }

  /// Deduce absolute file path of project's lib folder.
  ///
  /// Tests whether [import] file  is found in any found `lib` folder of the
  /// source path.
  Future<String?> _findProjectRoot(String sourcePath) async {
    // get component indices of all 'lib' folders in the source path
    final components = p.split(sourcePath);
    final libIndices = components
        .mapIndexed((i, name) => name == 'lib' ? i : -1)
        .where((i) => i != -1);

    // return first path from which we can access [import]
    for (int i = 0; i < libIndices.length; i++) {
      final projectRoot = components
          .take(libIndices.elementAt(i) + 1)
          .join(Platform.pathSeparator);

      final importPath = p.join(
        projectRoot,
        import,
      );

      if (await File(importPath).exists()) {
        // from this lib folder we can access the [import]
        return projectRoot;
      }
    }

    return null;
  }
}
