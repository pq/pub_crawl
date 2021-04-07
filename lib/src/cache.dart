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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'common.dart';
import 'package.dart';

typedef PackageIndexer = void Function(Package p, Cache index);

Directory _cacheDir = Directory('third_party/cache');
File _indexFile = File('third_party/index.json');

// todo (pq): add a cache clean command (to remove old / duplicated libraries)

class Index {
  dynamic _jsonData;

  Index();

  void read() {
    if (_jsonData != null) {
      return;
    }
    if (!_indexFile.existsSync()) {
      print('Cache index does not exist, creating...');
      _indexFile.createSync(recursive: true);
    }
    final contents = _indexFile.readAsStringSync();
    _jsonData = contents.isNotEmpty ? jsonDecode(contents) : {};
  }

  void write() {
    final encoder = JsonEncoder.withIndent('  ');
    _indexFile.writeAsStringSync(encoder.convert(_jsonData));
  }

  Package? getPackage(String name) => Package.fromData(name, _jsonData);

  void add(Package package) {
    package.addToJsonData(_jsonData);
  }

  bool containsSourcePath(String path) {
    for (var entry in _jsonData.entries) {
      if (path == entry.value['sourcePath']) {
        return true;
      }
    }
    return false;
  }
}

class Cache {
  final Index index;

  Directory get dir => _cacheDir;

  PackageIndexer? onProcess;

  Cache() : index = Index()..read();

  void process(Package package) async {
    var onProcess = this.onProcess;
    if (onProcess != null) {
      onProcess(package, this);
    }
  }

  bool isCached(Package package) => getSourceDir(package).existsSync();

  Future cache(Package package) async {
    final cached = await _download(package);
    if (cached) {
      index.add(package);
    }
  }

  bool hasDependenciesInstalled(Package package) {
    final sourceDir = getSourceDir(package);
    return sourceDir.existsSync() &&
        File('${sourceDir.path}/.packages').existsSync();
  }

  Future<Process> raceProcess(Future<Process> futureProcess, int timeout) {
    if (timeout <= 0) {
      // Nothing to do here
      return futureProcess;
    }
    // Wrap the futureProcess in timeout, and return it when it's ready (or throw if timeout exceeded!)
    return futureProcess.then((Process p) =>
        p.exitCode.timeout(Duration(seconds: timeout), onTimeout: () {
          Process.killPid(p.pid);
          throw Exception(
              'Process with PID ${p.pid} took longer than ${timeout}s to complete. Killed.');
        }).then((int exitCode) => p));
  }

  Future<Process?> installDependencies(Package package,
      {required int timeout}) async {
    print('${package.name}-${package.version}');
    final sourceDir = getSourceDir(package);
    final sourcePath = sourceDir.path;
    if (!sourceDir.existsSync()) {
      print(
          'Unable to install dependencies for ${package.name}: $sourcePath does not exist');
      return null;
    }

    if (package.dependencies?.containsKey('flutter') == true) {
      return raceProcess(
          Process.start(
              'flutter', ['packages', 'pub', 'get', '--no-precompile'],
              workingDirectory: sourcePath),
          timeout);
    }

    //TODO: recurse and run pub get in example dirs.
    print('Running "pub get" in ${path.basename(sourcePath)}');
    return raceProcess(
        Process.start('dart', ['pub', 'get', '--no-precompile'],
            workingDirectory: sourcePath),
        timeout);
  }

  Future<bool> _download(Package package) async {
    final name = package.name;
    final version = package.version;
    final url = package.archiveUrl;
    if (url == null) {
      print('Error downloading $url:\nno archive url available');
      return false;
    }
    try {
      // todo (pq): migrate to _downloadDir
      const downloadDir = 'third_party/download';
      if (!Directory(downloadDir).existsSync()) {
        print('Creating: $downloadDir');
        Directory(downloadDir).createSync(recursive: true);
      }

      var response = await getResponse(url);
      var tarFile = '$downloadDir/$name-$version.tar.gz';
      await File(tarFile).writeAsBytes(response.bodyBytes);
      var outputDir = 'third_party/cache/$name-$version';
      await Directory(outputDir).create(recursive: true);
      var result = await Process.run('tar', ['-xf', tarFile, '-C', outputDir]);
      if (result.exitCode != 0) {
        print('Could not extract $tarFile:\n${result.stderr}');
      } else {
        print('Extracted $outputDir');
        await File(tarFile).delete();
      }
    } catch (error) {
      print('Error downloading $url:\n$error');
      return false;
    }

    return true;
  }

  // todo (pq): refactor to share directory info.
  Directory getSourceDir(Package package) =>
      Directory('third_party/cache/${package.name}-${package.version}');

  List<Package> list({List<Criteria>? matching}) {
    final packages = <Package>[];
    if (_cacheDir.existsSync()) {
      for (var packageDir in _cacheDir.listSync()) {
        final versionedName = path.basename(packageDir.path);
        final separatorIndex = versionedName.indexOf('-');
        final packageName = versionedName.substring(0, separatorIndex);
        final indexedPackage = index.getPackage(packageName);
        if (indexedPackage != null) {
          for (var criteria in matching ?? <Criteria>[]) {
            if (!criteria.matches(indexedPackage)) {
              break;
            }
          }
          packages.add(indexedPackage);
        }
      }
    }

    return packages;
  }

  int size() => _cacheDir.existsSync() ? _cacheDir.listSync().length : 0;

  Future delete() =>
      _cacheDir.delete(recursive: true).then((_) => _indexFile.delete());
}
