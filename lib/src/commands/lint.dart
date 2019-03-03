import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:linter/src/rules.dart';
import 'package:pub_crawl/src/commands/analyze.dart';

class LintCommand extends AnalyzeCommand {
  final List<LintRule> enabledRules = <LintRule>[];

  LintCommand() : super() {
    argParser.addMultiOption('rules',
        help: 'A list of lint rules to run. For example: '
            'avoid_as,annotate_overrides.');
  }

  @override
  String get commandVerb => 'Linting';

  @override
  String get description => 'lint packages.';

  @override
  String get name => 'lint';

  @override
  void preAnalyze(AnalysisContext context) {
    final optionsImpl = context.analysisOptions as AnalysisOptionsImpl;
    optionsImpl.lint = true;
    optionsImpl.lintRules = enabledRules;
  }

  @override
  Future run() async {
    registerLintRules();

    final lints = argResults['rules'];
    if (lints == null || lints.isEmpty) {
      print('No lint rules specified.');
      printUsage();
      return;
    }
    if (lints != null && !lints.isEmpty) {
      for (var lint in lints) {
        final rule = Registry.ruleRegistry[lint];
        if (rule == null) {
          print('Unrecognized lint rule: $lint.');
          return;
        }
        enabledRules.add(rule);
      }
    }

    super.run();
  }

  @override
  bool showError(AnalysisError error) => error.errorCode is LintCode;
}
