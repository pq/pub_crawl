import 'package:pub_semver/pub_semver.dart';

final _dart2 = VersionConstraint.parse('>=2.0.0');

bool isDart2(String sdkVersion) =>
    VersionConstraint.parse(sdkVersion).allowsAny(_dart2);
