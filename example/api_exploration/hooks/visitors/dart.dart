//  Copyright 2019 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

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
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.name == 'debugFillProperties') {
      ++count;
    }
  }
}
