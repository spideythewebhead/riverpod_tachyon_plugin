Riverpod code generation powered by `Tachyon`.

### Information

This code generator produces _almost_ identical code to the official `riverpod_generator` but instead of using `build_runner`, it uses `tachyon`.

## Installation

1. In your project's `pubspec.yaml` add

  ```yaml
  dependencies:
    riverpod_annotation: any

  dev_dependencies:
    tachyon: any
    riverpod_tachyon_plugin: any
  ```

1. Create `tachyon_config.yaml` on the project's root folder

  ```yaml
  file_generation_paths: # which files/paths to include for build
    - "file/path/to/watch"
    - "another/one"

  generated_file_line_length: 80 # default line length

  plugins:
    - riverpod_tachyon_plugin # register riverpod_tachyon_plugin
  ```

## Code generation

You can now create providers the same way as you would with `build_runner`. The main difference is you need to change the part file to following this format `<file name>.gen.dart`

### Example

  ```dart
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  part 'user.gen.dart';

  class User {
    User({
      required this.id,
      required this.username,
    });

    final int id;
    final String username;
  }

  @riverpod
  User user(UserRef ref) {
    return User(id: 11, username: 'pantelis');
  }
  ```

Executing tachyon:

  `dart run tachyon build`

> See more options about tachyon by executing: `dart run tachyon --help`

Will produce the following code:

  ```dart
  part of 'user.dart';

  String _$userHash() => r'0c59864fbc5f80cdab48302d3bd7c942c878cb87';

  @ProviderFor(user)
  final userProvider = AutoDisposeProvider<User>.internal(
    user,
    name: r'userProvider',
    debugGetCreateSourceHash:
        const bool.fromEnvironment('dart.vm.product') ? null : _$userHash,
    dependencies: null,
    allTransitiveDependencies: null,
  );

  typedef UserRef = AutoDisposeProviderRef<User>;
  ```

See more [examples](https://github.com/spideythewebhead/riverpod_tachyon_plugin/tree/main/example).