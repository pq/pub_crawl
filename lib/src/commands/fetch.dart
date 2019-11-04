import 'dart:convert';

import '../../hooks/criteria/fetch.dart';
import '../cache.dart';
import '../common.dart';
import '../package.dart';

class FetchCommand extends BaseCommand {
  static const defaultFetchLimit = 10;

  @override
  String get description => 'fetch packages.';

  @override
  String get name => 'fetch';

  FetchCommand() {
    argParser.addOption('max', abbr: 'm', valueHelp: 'packages');
    argParser.addOption('criteria', abbr: 'c', valueHelp: 'crit_1,..,crit_n');
    argParser.addFlag('no-install', help: 'do not install dependencies.');
    argParser.addFlag('verbose', help: 'show verbose output.');
  }

  bool get install => !argResults['no-install'];

  @override
  Future run() async {
    final maxFetch = toInt(argResults['max'] ?? defaultFetchLimit);
    final criteria =
        Criteria.fromArgs(argResults['criteria']) ?? defaultFetchCriteria;

    int skipCount = 0;
    var packages = await _listPackages(criteria, maxFetch, onSkip: (p, c) {
      print('Skipped package:${p.name} (${c.onFail(p)})');
      ++skipCount;
    });

    var cache = Cache();
    cache.onProcess = (package, cache) async {
      if (!cache.isCached(package)) {
        await cache.cache(package);
      }

      if (install && !cache.hasDependenciesInstalled(package)) {
        print('Installing dependencies...');
        var result = await cache.installDependencies(package);
        if (result != null) {
          print(result.stdout);
          print(result.stderr);
        }
      }
    };

    for (var package in packages) {
      await cache.process(package);
    }

    await cache.index.write();

    if (skipCount > 0) {
      print('($skipCount packages skipped)');
    }

    return null;
  }

  Future<List<Package>> _listPackages(
    List<Criteria> criteria,
    int maxCount, {
    void onSkip(Package package, Criteria criteria),
  }) async {
    var count = 0;
    // todo (pq): https
    var packagePage = 'http://pub.dartlang.org/api/packages';
    print('Fetching package information from pub.dartlang.org...');
    final packages = <Package>[];
    while (packagePage != null && packages.length < maxCount) {
      final packageBody = jsonDecode(await getBody(packagePage));
      for (var packageData in packageBody['packages']) {
        final package = await RemotePackage.init(packageData);

        ++count;

        // Filter.
        final failedCriteria =
            criteria.firstWhere((c) => !c.matches(package), orElse: () => null);
        if (failedCriteria != null) {
          onSkip(package, failedCriteria);
          continue;
        }

        if (cache.isCached(package)) {
          if (verbose) {
            print('Skipped package:${package.name} (already cached)');
            continue;
          }
        }

        print('Adding package:${package.name}');

        packages.add(package);
        if (packages.length >= maxCount) {
          break;
        }
      }
      print(count);
      packagePage = packageBody['next_url'];
    }
    print('$count packages processed');
    if (packagePage == null) {
      print('(Processed all available packages on pub.)');
    } else {
      print('(Max processed package count of $maxCount reached.)');
    }

    print(count);

    return packages;
  }
}
