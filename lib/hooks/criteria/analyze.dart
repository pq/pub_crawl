import '../../src/common.dart';
import '../../src/package.dart';

// ignore_for_file: prefer_expression_function_bodies

/// Define default analyze command criteria here.
///
///
/// (Important: do not move or rename.)
List<Criteria> get defaultAnalyzeCriteria => <Criteria>[
      Criteria(matches: (Package p) {
        // Default to matching everything.
        return true;
      }, onFail: (Package p) {
        // No message.
        return null;
      })
    ];
