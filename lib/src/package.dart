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
import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

import 'common.dart';

class LocalPackage extends Package {
  @override
  String? archiveUrl;

  @override
  Directory dir;

  @override
  int pubPoints;

  @override
  int popularity;

  @override
  int likes;

  @override
  Map<String, dynamic>? pubspec;

  @override
  String name;

  @override
  String? repository;

  @override
  String version;

  @override
  String? sdkConstraint;

  LocalPackage({
    required this.name,
    required this.version,
    required this.pubPoints,
    required this.popularity,
    required this.likes,
    required this.dir,
  });

  @override
  Map<String, dynamic> get dependencies {
    final deps = _pubspec['dependencies']?.value;
    if (deps is yaml.YamlMap) {
      return deps.nodes
          .map((k, v) => MapEntry<String, dynamic>(k.toString(), v));
    }
    return {};
  }

  Map<dynamic, yaml.YamlNode> get _pubspec {
    var path = dir.path;
    final pubspecFile = File('$path/pubspec.yaml');
    if (pubspecFile.existsSync()) {
      try {
        return (yaml.loadYaml(pubspecFile.readAsStringSync()) as yaml.YamlMap)
            .nodes;
      } on yaml.YamlException {
        // Warn?
      }
    }
    return <dynamic, yaml.YamlNode>{};
  }

  @override
  String toString() => '$name-$version';
}

class Metrics {
  final dynamic _data;
  Metrics(this._data);

  int get grantedPoints => _data['score']['grantedPoints'];
  int get popularity {
    try {
      return (_data['score']['popularityScore'] * 100).round();
    } catch (_) {
      return -1;
    }
  }

  int get likes {
    try {
      return _data['score']['likeCount'];
    } catch (_) {
      return -1;
    }
  }
}

abstract class Package {
  Package();
  String? get archiveUrl;

  Map<String, dynamic>? get dependencies {
    var pubspec = this.pubspec;
    if (pubspec == null) {
      return null;
    }
    return pubspec['dependencies'];
  }

  Directory? get dir => null;

  String get name;

  int get pubPoints;

  int get popularity;

  int get likes;

  Map<String, dynamic>? get pubspec;

  String? get repository;

  String? get sdkConstraint;

  /// Cache-relative path to local package source.
  String get sourcePath => '$name-$version';

  String get version;

  void addToJsonData(dynamic jsonData) {
    jsonData[name] = {
      'version': version,
      'pubPoints': pubPoints,
      'popularity': popularity,
      'likes': likes,
      'sourcePath': sourcePath,
    };
  }

  bool isFlutterPackage() => dependencies?.containsKey('flutter') == true;

  static Package? fromData(String name, dynamic jsonData) {
    final packageData = jsonData[name];
    if (packageData == null) {
      return null;
    }

    final package = LocalPackage(
      name: name,
      version: packageData['version'],
      pubPoints: packageData['pubPoints'],
      popularity: packageData['popularity'],
      likes: packageData['likes'],
      dir: Directory('third_party/cache/${packageData['sourcePath']}'),
    );

    return package;
  }
}

class RemotePackage extends Package {
  final Map<String, dynamic> _data;

  Metrics? metrics;

  RemotePackage._(this._data);

  @override
  String get archiveUrl => _data['latest']['archive_url'];

  @override
  String get name => _data['name'];

  @override
  int get pubPoints => metrics?.grantedPoints ?? -1;
  @override
  int get popularity => metrics?.popularity ?? -1;
  @override
  int get likes => metrics?.likes ?? -1;
  @override
  Map<String, dynamic> get pubspec => _data['latest']['pubspec'];

  @override
  String get repository => pubspec['repository'];

  @override
  String? get sdkConstraint {
    final env = pubspec['environment'];
    return env == null ? null : env['sdk'];
  }

  @override
  String get version => _data['latest']['version'];

  static Future<Package> init(Map<String, dynamic> data) async {
    final package = RemotePackage._(data);
    final url =
        'https://pub.dartlang.org/api/packages/${package.name}/metrics?pretty&reports';
    final body = await getBody(url);
    try {
      var metricsData = jsonDecode(body);
      // print(JsonEncoder.withIndent('  ').convert(metricsData));
      package.metrics = Metrics(metricsData);
    } on FormatException catch (e) {
      print('unable to decode json from: $url');
      print(e);
      print(body);
      rethrow;
    }
    return package;
  }
}
