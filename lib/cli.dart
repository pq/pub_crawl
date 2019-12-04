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

import 'package:args/command_runner.dart';

import 'src/commands/analyze.dart';
import 'src/commands/cache.dart';
import 'src/commands/clean.dart';
import 'src/commands/fetch.dart';
import 'src/commands/lint.dart';

const String toolName = 'pub_crawl';
const String toolDescription = 'Fetches, caches and queries pub packages.';

class Cli extends CommandRunner {
  Cli() : super(toolName, toolDescription) {
    addCommand(AnalyzeCommand());
    addCommand(CacheCommand());
    addCommand(CleanCommand());
    addCommand(FetchCommand());
    addCommand(LintCommand());
  }

  @override
  Future run(Iterable<String> args) async {
//    print(Ansi.terminalSupportsAnsi);
    final results = parse(args);
    return runCommand(results);
  }
}
