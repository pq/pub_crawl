import 'package:pub_crawl/src/common.dart';

class ListCommand extends BaseCommand {
  @override
  String get description => 'list cached packages meeting given criteria.';

  @override
  String get name => 'list';

  Future run() {
    print(argResults.arguments);
    return Future.value();
  }
}
