import 'package:pub_crawl/src/common.dart';

class CleanCommand extends BaseCommand {
  @override
  String get description => 'delete cached packages.';

  @override
  String get name => 'clean';

  Future run() async {
    print('Deleting cache...');
    await cache.delete();
  }
}
