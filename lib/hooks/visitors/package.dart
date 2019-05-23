import 'dart:io';

import 'package:pub_crawl/src/common.dart';

/// Passed to all analyzed package roots.
///
/// Define your custom options analyses here! 👍
///
/// (Important: do not move or rename.)
class PackageVisitor extends PackageRootVisitor {
  int packages = 0;
  List<String> packagesWithBoth = <String>[];
  List<String> packagesWithJustAndroid = <String>[];
  List<String> packagesWithJustIOs = <String>[];

  @override
  void visit(Directory root) {
    ++packages;
    var p = root.absolute.path;
    var android = Directory('$p/android').existsSync();
    var ios = Directory('$p/ios').existsSync();
    if (android && !ios) {
      packagesWithJustAndroid.add(p);
    } else if (ios && !android) {
      packagesWithJustIOs.add(p);
    } else if (ios && android) {
      packagesWithBoth.add(p);
    }
  }

  /// Called after all packages have been visited.
  ///
  /// (Useful for processing reports.)
  void postVisit() {
    print('| packages | android & ios | just android | just ios | ');
    print('| :--- | :---  | :--- | :--- | ');
    print(
        '| $packages | ${packagesWithBoth.length} | ${packagesWithJustAndroid.length} | ${packagesWithJustIOs.length} | ');

    if (packagesWithBoth.isNotEmpty) {
      print('\nandroid & ios');
      print(packagesWithBoth.join('\n'));
    }

    if (packagesWithJustAndroid.isNotEmpty) {
      print('\njust android');
      print(packagesWithJustAndroid.join('\n'));
    }

    if (packagesWithJustIOs.isNotEmpty) {
      print('\njust ios');
      print(packagesWithJustIOs.join('\n'));
    }

    //TMP
    exit(0);
  }
}
