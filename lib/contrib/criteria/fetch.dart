import 'package:pub_crawl/src/common.dart';
import 'package:pub_crawl/src/package.dart';

/// Define default fetch criteria here.
///
///
/// (Important: do not move or rename.)
List<Criteria> get defaultFetchCriteria => <Criteria>[
      Criteria(matches: (Package p) {
        // Default to matching everything.
        return true;
      }, onFail: (Package p) {
        // No message.
        return null;
      })
    ];
