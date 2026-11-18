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

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

final plugin = _AppLinter();

class _AppLinter extends Plugin {
  @override
  String get name => 'Yubico Authenticator lints';

  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(UseRecommendedWidget());
    registry.registerLintRule(CallInitAfterCreation());
  }
}

class UseRecommendedWidget extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_recommended_widget',
    'Use recommended AppTextField instead of TextField.',
  );

  UseRecommendedWidget()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(this, _WidgetVisitor(this));
  }
}

class _WidgetVisitor extends SimpleAstVisitor<void> {
  final UseRecommendedWidget rule;

  _WidgetVisitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.toString() == 'TextField') {
      rule.reportAtNode(node.constructorName);
    }
  }
}

class CallInitAfterCreation extends AnalysisRule {
  static const LintCode code = LintCode(
    'call_init_after_creation',
    'Call init() after creation',
  );

  CallInitAfterCreation()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(this, _InitVisitor(this));
  }
}

class _InitVisitor extends SimpleAstVisitor<void> {
  final CallInitAfterCreation rule;

  _InitVisitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.toString() != 'AppTextField') return;
    final dot = node.endToken.next;
    final next = dot?.next;
    if (dot?.type == TokenType.PERIOD &&
        next?.type == TokenType.IDENTIFIER &&
        next?.lexeme == 'init') {
      return;
    }
    rule.reportAtNode(node.constructorName);
  }
}
