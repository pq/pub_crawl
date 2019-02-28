import 'package:pub_crawl/src/common.dart';

/// Passed to all analyzed analysis options.
///
/// Define your custom options analyses here! 👍
///
/// (Important: do not move or rename.)

class OptionsVisitor extends AnalysisOptionsVisitor {
  @override
  void visit(AnalysisOptionsFile options) {
    //print('>> visiting: ${options.file}');
  }
}
