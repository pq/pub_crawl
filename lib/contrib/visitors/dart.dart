import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Passed to all analyzed Dart compilation units.
///
/// Define your custom Dart analyses here! 👍
///
/// (Important: do not move or rename.)
class AstVisitor extends GeneralizingAstVisitor {

  /// Called on visit finish.
  void onVisitFinish() {
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
//    print('... visiting ${node.name.name}');
  }
}
