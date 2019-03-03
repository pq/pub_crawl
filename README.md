# Pub Crawl 🍻

A tool for fetching and exploring published `pub` packages.

## Sample Applications

The kinds of investigations `pub_crawl` was designed to support include ones like:

* API Exploration - who's using this API and how?  How impactful would a breaking change be?
* Lint Rule Testing - how does a new our existing rule perform on code in the wild?
* Language Experiment Testing - do existing packages continue to analyze cleanly when we enable an experiment?

In the future, we'd like to add a `migrate` command to auto-apply code migrations for bulk analysis.

## Usage

Pub crawl is run as a command-line tool.  Running from source is recommended as that allows you to
customize behavior in provided "hook" classes.

Supported commands are:

* `pub fetch` - fetch packages that match given criteria (for example, `fetch --max 5 --criteria flutter,min_score:.75`
   fetches Flutter packages whose pub score is 75 or higher)
* `pub analyze` - analyze packages
* `pub lint` - a variation of `analyze` that makes it easy to lint packages with specified rules
   (for example, `lint --rules=await_only_futures,avoid_as`)
* `pub clean` - deletes cached packages

For example, the sequence

```
dart bin/pub_crawl.dart fetch --max 10 --criteria flutter
dart bin/pub_crawl.dart analyze
```

fetches 10 Flutter packages and then analyzes them.

### Filtering Fetches and Analyses with Criteria

Fetching and analysis can be directed by "criteria" that act as predicates, filtering
packages on qualities of interest.  `pub_crawl` defines a few criteria:

* `flutter` - filters on packages that depend on Flutter
* `min_score:` - filters on overall pub package score (see the [pub scoring docs] for details)

Using criteria we can limit a `fetch` to Flutter packages that score .75 or higher like this:

    dart bin/pub_crawl.dart --criteria flutter,min_score:.75

If you want to define your own criteria, you can do so by adding a hook.

### Adding Your own Hooks

You can customize various aspects of `pub_crawl` by adding your own logic to a number of
files that define hooks that are called during command execution.

```
lib/   
  hooks/
     criteria/
       analyze.dart
       fetch.dart
     visitors/
       dart.dart
       options.dart
       pubspec.dart
```

If you wanted to count declarations of methods of a given name, for example, you could
update `visitors.dart` like this:

```dart
class AstVisitor extends GeneralizingAstVisitor {
  int count = 0;

  void onVisitFinish() {
    print('Matched $count declarations');
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.name == 'debugFillProperties') {
      ++count;
    }
  }
}
```

More examples live in the [example](example) directory. 


[pub scoring docs]: https://pub.dartlang.org/help#scoring
