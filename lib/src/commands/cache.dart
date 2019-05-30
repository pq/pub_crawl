import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:pub_crawl/src/common.dart';

// todo (pq): change this to cache, with list as a sub command and add clean

class CacheCommand extends BaseCommand {
  CacheCommand() {
    addSubcommand(ListSubCommand());
    addSubcommand(CacheStatsCommand());
    addSubcommand(CacheCleanSubCommand());
  }

  @override
  String get description => 'cache commands.';

  @override
  String get name => 'cache';

//  @override
//  Future run() {
//    print(cache.size());
//    return Future.value();
//  }
}

class ListSubCommand extends BaseCommand {
  ListSubCommand() {
    addSubcommand(CacheSizeCommand());
  }

  @override
  String get description => 'package cache commands';

  @override
  String get name => 'cache';
}

class CacheCleanSubCommand extends BaseCommand {
  @override
  String get description => 'clean cache (remove stale packages)';

  @override
  String get name => 'clean';

  @override
  Future run() {
    var staleDirs = <String>[];

    for (var packageDir in cache.dir.listSync(followLinks: false)) {
      if (!cache.index.containsSourcePath(path.basename(packageDir.path))) {
        staleDirs.add(packageDir.path);
      }
    }

    staleDirs.sort();
    staleDirs.forEach(print);

    return Future.value();
  }
}

class CacheSizeCommand extends BaseCommand {
  @override
  String get description => 'list cache size';

  @override
  String get name => 'size';

  @override
  Future run() {
    print(cache.size());
    return Future.value();
  }
}

class CacheStatsCommand extends BaseCommand {
  @override
  String get description => 'list cache stats';

  @override
  String get name => 'stats';

  @override
  Future run() {
    print('Total cache size: ${cache.size()}');

    var flutterPackageCount = 0;
    var flutterPluginCount = 0;
    List<String> packagesWithBoth = <String>[];
    List<String> packagesWithJustAndroid = <String>[];
    List<String> packagesWithJustIOs = <String>[];

    for (var package in cache.list()) {
      if (package.isFlutterPackage()) {
        ++flutterPackageCount;
        final p = package.dir?.path;
        if (p != null) {
          var android = Directory('$p/android').existsSync();
          var ios = Directory('$p/ios').existsSync();
          if (android || ios) {
            ++flutterPluginCount;
            if (android && !ios) {
              packagesWithJustAndroid.add(p);
            } else if (ios && !android) {
              packagesWithJustIOs.add(p);
            } else if (ios && android) {
              packagesWithBoth.add(p);
            }
          }
        }
      }
    }

    // todo (pq): format output
    print('Flutter packages: $flutterPackageCount');
    print('Flutter plugins: $flutterPluginCount');
    if (packagesWithBoth.isNotEmpty) {
      print('  android & ios: ${packagesWithBoth.length}');
    }
    if (packagesWithJustAndroid.isNotEmpty) {
      print('  just android: ${packagesWithJustAndroid.length}');
    }
    if (packagesWithJustIOs.isNotEmpty) {
      print('  just ios: ${packagesWithJustIOs.length}');
    }

    return Future.value();
  }
}
