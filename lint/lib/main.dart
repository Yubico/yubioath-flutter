/*
 * Copyright (C) 2023-2026 Yubico.
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
    registry.registerLintRule(NoPlatformErrorTypes());
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

/// Keeps backend-specific error types inside the platform layers.
///
/// The desktop helper and the Android native code report errors as `RpcError`
/// and `PlatformException`. `lib/desktop` and `lib/android` turn them into
/// `AppException` (see doc/Error_Contract.adoc), so the rest of the app is
/// platform agnostic.
class NoPlatformErrorTypes extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_platform_error_types',
    "Don't use '{0}' outside lib/desktop and lib/android.",
    correctionMessage: 'Handle the matching AppException type instead.',
  );

  static const _platformErrorTypes = {'RpcError', 'PlatformException'};

  static final _platformLayer = RegExp(r'[/\\]lib[/\\](desktop|android)[/\\]');

  NoPlatformErrorTypes()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;
    if (_platformLayer.hasMatch(context.definingUnit.file.path)) return;
    registry.addNamedType(this, _PlatformErrorTypeVisitor(this));
  }
}

class _PlatformErrorTypeVisitor extends SimpleAstVisitor<void> {
  final NoPlatformErrorTypes rule;

  _PlatformErrorTypeVisitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    final name = node.name.lexeme;
    if (NoPlatformErrorTypes._platformErrorTypes.contains(name)) {
      rule.reportAtNode(node, arguments: [name]);
    }
  }
}
