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

import 'dart:convert';
import 'dart:io' as io;

import 'package:collection/collection.dart';
import 'package:pool/pool.dart';

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
        defaultsTo: '-1');
    argParser.addFlag('install',
        help: 'install dependencies.', defaultsTo: true);
    argParser.addFlag('verbose',
        help: 'show verbose output.', negatable: false);
  }

  @override
  String get description => 'fetch packages.';

  bool get install => argResults!['install'];

  @override
  String get name => 'fetch';

  @override
  Future run() async {
    final maxFetch = toInt(argResults!['max'] ?? defaultFetchLimit);
    final timeout = toInt(argResults!['timeout'] ?? -1);

    final criteria =
        Criteria.fromArgs(argResults!['criteria']) ?? defaultFetchCriteria;

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
          var process =
              await cache.installDependencies(package, timeout: timeout);
          if (verbose && process != null) {
            process
              ..stdout.listen(io.stdout.add)
              ..stderr.listen(io.stderr.add);
          }
        } catch (e) {
          print(e);
        }
      }
    };

    for (var package in packages) {
      cache.process(package);
    }

    cache.index.write();

    if (skipCount > 0) {
      print('($skipCount packages skipped)');
    }

    return null;
  }

  Future<List<Package>> _listPackages(
    List<Criteria> criteria,
    int maxCount, {
    required void Function(Package package, Criteria criteria) onSkip,
  }) async {
    var count = 0;
    // todo (pq): https
    final packagePage = 'http://pub.dartlang.org/api/packages';
    print('Fetching package information from pub.dartlang.org...');
    final allPackageNames = List<String>.from(
        jsonDecode(await getBody('$packagePage?compact=1'))['packages']);
    final packages = <Package>[];

    // Asynchronously adds the package referenced by `name` to `packages`,
    // and then releases `resource`.
    void addPackage(String name, PoolResource resource) async {
      try {
        var pkgData = jsonDecode(await getBody('$packagePage/$name'))
            as Map<String, dynamic>;
        var error = pkgData['error'];
        if (error != null) {
          print('Package not found `$name`');
          return;
        }
        final package = await RemotePackage.init(pkgData);

        ++count;

        var sdkConstraint = package.sdkConstraint;
        if (sdkConstraint == null) {
          if (verbose) {
            print('Skipped package:${package.name} (no SDK constraint)');
          }
          return;
        }

        if (!isDart2(sdkConstraint)) {
          if (verbose) {
            print('Skipped package:${package.name} (not Dart2)');
          }
          return;
        }

        // Filter.
        final failedCriteria =
            criteria.firstWhereOrNull((c) => !c.matches(package));

        if (failedCriteria != null) {
          onSkip(package, failedCriteria);
          return;
        }

        if (cache.isCached(package)) {
          if (verbose) {
            print('Skipped package:${package.name} (already cached)');
            return;
          }
        }

        if (packages.length < maxCount) {
          print('Adding package:${package.name}');
          packages.add(package);
        }
      } finally {
        resource.release();
      }
    }

    for (var name in allPackageNames) {
      var resource = await _requestPool.request();
      if (packages.length >= maxCount) {
        print('(Max processed package count of $maxCount reached.)');
        resource.release();
        break;
      }
      addPackage(name, resource);
    }

    if (count == allPackageNames.length) {
      print('(Processed all available packages on pub.)');
    }

    print('---');

    return packages;
  }
}

// Pool to limit the number of concurrent requests.
final _requestPool = Pool(10);
