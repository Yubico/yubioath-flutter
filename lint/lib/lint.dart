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

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _AppLinter();

class _AppLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    UseRecommendedWidget(discouraged: 'TextField', recommended: 'AppTextField'),
    const CallInitAfterCreation(className: 'AppTextField'),
  ];
}

/// recommend to use App Widgets
class UseRecommendedWidget extends DartLintRule {
  final String discouraged;
  final String recommended;

  UseRecommendedWidget({required this.discouraged, required this.recommended})
    : super(
        code: LintCode(
          name: 'use_recommended_widget',
          problemMessage:
              'Use recommended $recommended instead of $discouraged.',
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.constructorName.toString() == discouraged) {
        reporter.atNode(node.constructorName, code);
      }
    });
  }
}

class CallInitAfterCreation extends DartLintRule {
  final String className;

  const CallInitAfterCreation({required this.className})
    : super(
        code: const LintCode(
          name: 'call_init_after_creation',
          problemMessage: 'Call init() after creation',
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.constructorName.toString() == className) {
        final dot = node.endToken.next;
        final next = dot?.next;
        if (dot?.type == TokenType.PERIOD) {
          if (next?.type == TokenType.IDENTIFIER &&
              next?.toString() == 'init') {
            return;
          }
        }
        reporter.atNode(node.constructorName, code);
      }
    });
  }
}
