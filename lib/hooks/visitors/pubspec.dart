import 'package:pub_crawl/src/common.dart';

/// Passed to all analyzed pubspecs.
///
/// Define your custom pubspec analyses here! 👍
///
/// (Important: do not move or rename.)
class PubspecVisitor extends PubspecFileVisitor {
  @override
  void visit(PubspecFile pubspec) {
//    print('>> visiting: ${pubspec.file}');
  }
}
