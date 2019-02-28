import 'package:args/command_runner.dart';
import 'package:pub_crawl/src/commands/analyze.dart';
import 'package:pub_crawl/src/commands/clean.dart';
import 'package:pub_crawl/src/commands/fetch.dart';
import 'package:pub_crawl/src/commands/list.dart';

const String toolName = 'pub_crawl';
const String toolDescription = 'Fetches, caches and queries pub packages.';

class Cli extends CommandRunner {
  Cli() : super(toolName, toolDescription) {
    addCommand(AnalyzeCommand());
    addCommand(FetchCommand());
    addCommand(ListCommand());
    addCommand(CleanCommand());
  }

  @override
  Future run(Iterable<String> args) async {
//    print(Ansi.terminalSupportsAnsi);
    final results = parse(args);
    return runCommand(results);
  }
}
