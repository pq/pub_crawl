import 'dart:convert';
import 'dart:io' as io;

import '../../hooks/criteria/fetch.dart';
import '../cache.dart';
import '../common.dart';
import '../filters.dart';
import '../package.dart';

class FetchCommand extends BaseCommand {
  static const defaultFetchLimit = 10;

  FetchCommand() {
    argParser.addOption('criteria', abbr: 'c', valueHelp: 'crit_1,..,crit_n');
    argParser.addOption('max',
        abbr: 'm',
        valueHelp: 'packages',
        help: 'number of packages to download.',
        defaultsTo: defaultFetchLimit.toString());
    argParser.addOption('timeout',
        valueHelp: 'seconds',
        help: 'time allotted for the download of each package.',
        defaultsTo: 'disabled');
    argParser.addFlag('install',
        help: 'install dependencies.', defaultsTo: true);
    argParser.addFlag('verbose',
        help: 'show verbose output.', negatable: false);
  }

  @override
  String get description => 'fetch packages.';

  bool get install => argResults['install'];

  @override
  String get name => 'fetch';

  @override
  Future run() async {
    final maxFetch = toInt(argResults['max'] ?? defaultFetchLimit);
    final timeout = toInt(argResults['timeout'] ?? -1);

    final criteria =
        Criteria.fromArgs(argResults['criteria']) ?? defaultFetchCriteria;

    var skipCount = 0;
    var packages = await _listPackages(criteria, maxFetch, onSkip: (p, c) {
      print('Skipped package: ${p.name} (${c.onFail(p)})');
      ++skipCount;
    });

    var cache = Cache();
    cache.onProcess = (package, cache) async {
      if (!cache.isCached(package)) {
        await cache.cache(package);
      }

      if (install && !cache.hasDependenciesInstalled(package)) {
        print('Installing dependencies for ${package.name}');
        try {
          if (verbose) {
            await cache.installDependencies(package, timeout: timeout)
              ..stdout.listen(io.stdout.add)
              ..stderr.listen(io.stderr.add);
          } else {
            await cache.installDependencies(package, timeout: timeout);
          }
        } catch (e) {
          print(e);
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
    void Function(Package package, Criteria criteria) onSkip,
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

        if (!isDart2(package.sdkConstraint)) {
          if (verbose) {
            print('Skipped package:${package.name} (not Dart2)');
          }
          continue;
        }

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
      packagePage = packageBody['next_url'];
    }
    print('$count packages processed');
    if (packagePage == null) {
      print('(Processed all available packages on pub.)');
    } else {
      print('(Max processed package count of $maxCount reached.)');
    }

    print('---');

    return packages;
  }
}
