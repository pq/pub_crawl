import 'package:args/command_runner.dart';
import 'package:pub_crawl/src/commands/analyze.dart';
import 'package:pub_crawl/src/commands/clean.dart';
import 'package:pub_crawl/src/commands/fetch.dart';
import 'package:pub_crawl/src/commands/lint.dart';
import 'package:pub_crawl/src/commands/cache.dart';

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
