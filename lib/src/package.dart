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

import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

class LocalPackage extends Package {
  LocalPackage({
    required this.name,
    required this.version,
    required this.overallScore,
    required this.popularityScore,
    required this.maintenanceScore,
    required this.healthScore,
    required this.dir,
  });

  @override
  String? archiveUrl;

  @override
  Directory dir;

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

  @override
  double overallScore;

  @override
  double popularityScore;

  @override
  double maintenanceScore;
  @override
  double healthScore;
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

//    return pubspecFile.existsSync()
//        ? (yaml.loadYaml(pubspecFile.readAsStringSync()) as yaml.YamlMap).nodes
//        : <String, dynamic>{};
//    }
//    return _pubspec;
  }

  @override
  String toString() => '$name-$version';
}

class Metrics {
  final _data;
  Metrics(this._data);

  double get health => _getScorecardMetric('healthScore');

  double get maintenance => _getScorecardMetric('maintenanceScore');
  double get overall => _getScorecardMetric('overallScore');
  double get popularity => _getScorecardMetric('popularityScore');
  double _getScorecardMetric(String name) =>
      _data['scorecard'] != null ? _data['scorecard'][name] : -1;
}

abstract class Package {
  Package();
  static Package? fromData(String name, dynamic jsonData) {
    final packageData = jsonData[name];
    if (packageData == null) {
      return null;
    }

    final package = LocalPackage(
      name: name,
      version: packageData['version'],
      overallScore: packageData['score'],
      popularityScore: packageData['popularity'],
      maintenanceScore: packageData['maintenance'],
      healthScore: packageData['health'],
      dir: Directory('third_party/cache/${packageData['sourcePath']}'),
    );

    return package;
  }

  String? get archiveUrl;
  Map<String, dynamic>? get dependencies {
    var pubspec = this.pubspec;
    if (pubspec == null) {
      return null;
    }
    return pubspec['dependencies'];
  }

  Directory? get dir => null;

  double get healthScore;

  double get maintenanceScore;

  String get name;

  double get overallScore;

  double get popularityScore;

  Map<String, dynamic>? get pubspec;

  String? get repository;

  String? get sdkConstraint;

  /// Cache-relative path to local package source.
  String get sourcePath => '$name-$version';

  String get version;

  void addToJsonData(dynamic jsonData) {
    jsonData[name] = {
      'version': version,
      'score': overallScore,
      'popularity': popularityScore,
      'maintenance': maintenanceScore,
      'health': healthScore,
      'sourcePath': sourcePath,
    };
  }

  bool isFlutterPackage() => dependencies?.containsKey('flutter') == true;
}

class RemotePackage extends Package {
  final Map<String, dynamic> _data;

  // todo(pq):fix or remove metrics (https://github.com/pq/pub_crawl/issues/14)
  Metrics? metrics;

  RemotePackage._(this._data);

  @override
  String get archiveUrl => _data['latest']['archive_url'];

  @override
  double get healthScore => metrics?.health ?? -1;

  @override
  double get maintenanceScore => metrics?.maintenance ?? -1;

  @override
  String get name => _data['name'];

  @override
  double get overallScore => metrics?.overall ?? -1;

  @override
  double get popularityScore => metrics?.popularity ?? -1;

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
    // todo(pq):fix or remove metrics (https://github.com/pq/pub_crawl/issues/14)
    // final url =
    //     'https://pub.dartlang.org/api/packages/${package.name}/metrics?pretty&reports';
    // final body = await getBody(url);
    // try {
    //   var metricsData = jsonDecode(body);
    //   package.metrics = Metrics(metricsData);
    // } on FormatException catch (e) {
    //   print('unable to decode json from: $url');
    //   print(e);
    //   print(body);
    //   rethrow;
    // }
    return package;
  }
}
