import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:pub_crawl/src/commands/analyze.dart';

class FakeLint extends LintRule implements NodeLintRule {
  FakeLint()
      : super(
            name: 'fake_lint',
            description: 'fake lint',
            details: 'not more to say',
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class LintCommand extends AnalyzeCommand {

  @override
  String get description => 'lint packages.';

  @override
  String get name => 'lint';

  LintCommand() :
    super() {
    argParser.addMultiOption('rules',
        help: 'A list of lint rules to run. For example: '
            'avoid_as,annotate_overrides.');
  }

  void preAnalyze(AnalysisContext context) {
    final optionsImpl = context.analysisOptions as AnalysisOptionsImpl;
    optionsImpl.lint = true;
    optionsImpl.lintRules = enabledRules;
  }

  final List<LintRule> enabledRules = <LintRule>[];

  Future run() async {

    /// TMP
    final lint = FakeLint();

    if (Registry.ruleRegistry[lint.name] == null) {
      Registry.ruleRegistry.register(lint);
    }

    var lints = argResults['rules'];
    if (lints == null || lints.isEmpty) {
      print('No lint rules defined.');
      printUsage();
      return;
    }
    if (lints != null && !lints.isEmpty) {
      for (var lint in lints) {
        var rule = Registry.ruleRegistry[lint];
        if (rule == null) {
          print('Unrecognized lint rule: $lint');
          return;
        }
        enabledRules.add(rule);
      }
    }

    super.run();
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    print('... fake lint visiting ${node.name.name}');
    rule.reportLint(node);
  }
}
