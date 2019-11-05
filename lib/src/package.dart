import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

import 'common.dart';

abstract class Package {
  double get overallScore;
  double get popularityScore;
  double get maintenanceScore;
  double get healthScore;

  /// Cache-relative path to local package source.
  String get sourcePath => '$name-$version';

  String get name;

  String get archiveUrl;

  String get version;

  String get sdkConstraint;

  Directory get dir => null;

  Map<String, dynamic> get dependencies => pubspec['dependencies'];

  Map<String, dynamic> get pubspec;

  String get repository;

  Package();

  factory Package.fromData(String name, dynamic jsonData) {
    final packageData = jsonData[name];
    if (packageData == null) {
      return null;
    }

    final package = LocalPackage();
    package.name = name;
    package.version = packageData['version'];
    package.overallScore = packageData['score'];
    package.popularityScore = packageData['popularity'];
    package.maintenanceScore = packageData['maintenance'];
    package.healthScore = packageData['health'];
    package.dir = Directory('third_party/cache/${packageData['sourcePath']}');
    return package;
  }

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

class LocalPackage extends Package {
  @override
  String archiveUrl;

  @override
  Directory dir;

  @override
  Map<String, dynamic> pubspec;

  @override
  String name;

  @override
  Map<String, dynamic> get dependencies {
    if (_pubspec == null) {
      return {};
    }

    final deps = _pubspec['dependencies']?.value;
    if (deps is yaml.YamlMap) {
      return deps.nodes
          .map((k, v) => MapEntry<String, dynamic>(k.toString(), v));
    }

//    deps.

    return {};
  }

  Map<dynamic, yaml.YamlNode> get _pubspec {
//    if (_pubspec == null) {
    final pubspecFile = File('${dir.path}/pubspec.yaml');
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
  String repository;

  @override
  String version;

  @override
  String sdkConstraint;

  @override
  double overallScore;
  @override
  double popularityScore;
  @override
  double maintenanceScore;
  @override
  double healthScore;

  @override
  String toString() => '$name-$version';
}

class RemotePackage extends Package {
  final Map<String, dynamic> _data;

  Metrics metrics;

  RemotePackage._(this._data);

  static Future<Package> init(Map<String, dynamic> data) async {
    final package = RemotePackage._(data);
    final url =
        'https://pub.dartlang.org/api/packages/${package.name}/metrics?pretty&reports';
    final body = await getBody(url);
    try {
      var metricsData = jsonDecode(body);
      package.metrics = Metrics(metricsData);
    } on FormatException catch (e) {
      print('unable to decode json from: $url');
      print(e);
      print(body);
      rethrow;
    }
    return package;
  }

  @override
  String get name => _data['name'];

  @override
  String get archiveUrl => _data['latest']['archive_url'];

  @override
  String get version => _data['latest']['version'];

  @override
  Map<String, dynamic> get pubspec => _data['latest']['pubspec'];

  @override
  String get repository => pubspec['repository'];

  @override
  double get overallScore => metrics.overall;

  @override
  double get popularityScore => metrics.popularity;

  @override
  double get maintenanceScore => metrics.maintenance;

  @override
  double get healthScore => metrics.health;

  @override
  String get sdkConstraint {
    final env = pubspec['environment'];
    return env == null ? null : env['sdk'];
  }
}

class Metrics {
  final _data;

  Metrics(this._data);

  double _getScorecardMetric(String name) => _data['scorecard'] != null ? _data['scorecard'][name] : null;

  double get overall => _getScorecardMetric('overallScore');
  double get popularity => _getScorecardMetric('popularityScore');
  double get maintenance => _getScorecardMetric('maintenanceScore');
  double get health => _getScorecardMetric('healthScore');
}
