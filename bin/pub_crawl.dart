import 'package:pub_crawl/cli.dart';

main(List<String> arguments) async {
  await Cli().run(arguments).catchError((e, st) {
    print(e);
    print(st);
  });
}
