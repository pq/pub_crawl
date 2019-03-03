import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Visitor hooks can be useful for understanding API use, for example when
/// trying to understand idiomatic use or measuring impact of breaking changes.
///
/// This simple example counts `debugFillProperties` method declarations.
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
