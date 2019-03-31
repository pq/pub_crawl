import 'dart:convert';

import 'package:pub_crawl/src/common.dart';

abstract class Package {
  double get overallScore;

  /// Cache-relative path to local package source.
  String get sourcePath => '$name-$version';

  String get name;

  String get archiveUrl;

  String get version;

  Map<String, dynamic> get dependencies;

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
    return package;
  }

  void addToJsonData(dynamic jsonData) {
    jsonData[name] = {
      'version': version,
      'score': overallScore,
      'sourcePath': sourcePath,
    };
  }
}

class LocalPackage extends Package {
  @override
  String archiveUrl;

  @override
  Map<String, dynamic> dependencies;

  @override
  String name;

  @override
  Map<String, dynamic> pubspec;

  @override
  String repository;

  @override
  String version;

  @override
  double overallScore;

  @override
  String toString() => '$name-$version';
}

class RemotePackage extends Package {
  final Map<String, dynamic> _data;

  Metrics metrics;

  RemotePackage._(this._data);

  static Future<Package> init(Map<String, dynamic> data) async {
    final package = RemotePackage._(data);
    var metricsData = jsonDecode((await getBody(
        'https://pub.dartlang.org/api/packages/${package.name}/metrics?pretty&reports')));
    package.metrics = new Metrics(metricsData);
    return package;
  }

  @override
  String get name => _data['name'];

  @override
  String get archiveUrl => _data['latest']['archive_url'];

  @override
  String get version => _data['latest']['version'];

  @override
  Map<String, dynamic> get dependencies => pubspec['dependencies'];

  @override
  Map<String, dynamic> get pubspec => _data['latest']['pubspec'];

  @override
  String get repository => pubspec['repository'];

  @override
  double get overallScore => metrics.overallScore;
}

class Metrics {
  var _data;

  Metrics(this._data);

  double get overallScore {
    var scorecard = _data['scorecard'];
    return scorecard != null ? scorecard['overallScore'] : null;
  }
}
