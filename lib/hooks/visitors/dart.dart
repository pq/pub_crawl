import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Passed to all analyzed Dart compilation units.
///
/// Define your custom Dart analyses here! 👍
///
/// (Important: do not move or rename.)
class AstVisitor extends GeneralizingAstVisitor {

  int count = 0;

  /// Called on visit finish.
  void onVisitFinish() {
    print('Matched $count declarations');
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.name == 'debugFillProperties') {
      ++count;
    }
  }
}
