// AUTO GENERATED - DO NOT MODIFY
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, inference_failure_on_uninitialized_variable, inference_failure_on_function_return_type, inference_failure_on_untyped_parameter, deprecated_member_use_from_same_package
// coverage:ignore-file

part of 'example.dart';

String _$userHash() => r'5de4c4d0bb6f42935b4065516553e6c7f28be488';

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

String _$usersHash() => r'2c75a21f24f0f57ccb18251c6f3b767efaf09943';

@ProviderFor(users)
final usersProvider = FutureProvider<List<User>>.internal(
  users,
  name: r'usersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$usersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UsersRef = FutureProviderRef<List<User>>;

String _$postNotifierHash() => r'bf5715f1ce77b8b6cf1d5f3e35d4818aa1135fed';

abstract class _$PostNotifier extends BuildlessAutoDisposeNotifier<Post> {
  late final int postId;

  Post build(int postId);
}

@ProviderFor(PostNotifier)
const postNotifierProvider = PostNotifierFamily();

class PostNotifierFamily extends Family<Post> {
  const PostNotifierFamily();

  PostNotifierProvider call(int postId) {
    return PostNotifierProvider(postId);
  }

  @visibleForOverriding
  @override
  PostNotifierProvider getProviderOverride(
    covariant PostNotifierProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postNotifierProvider';
}

class PostNotifierProvider
    extends AutoDisposeNotifierProviderImpl<PostNotifier, Post> {
  PostNotifierProvider(int postId)
      : this._internal(
          () => PostNotifier()..postId = postId,
          from: postNotifierProvider,
          name: r'postNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postNotifierHash,
          dependencies: PostNotifierFamily._dependencies,
          allTransitiveDependencies:
              PostNotifierFamily._allTransitiveDependencies,
          postId: postId,
        );

  PostNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  late final int postId;

  @override
  Post runNotifierBuild(
    covariant PostNotifier notifier,
  ) {
    return notifier.build(postId);
  }

  @override
  Override overrideWith(PostNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PostNotifierProvider._internal(
        () => create()..postId = postId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  (int,) get argument {
    return (postId,);
  }

  @override
  AutoDisposeNotifierProviderElement<PostNotifier, Post> createElement() {
    return _PostNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PostNotifierProvider &&
            runtimeType == other.runtimeType &&
            other.postId == postId;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      postId,
    ]);
  }
}

mixin PostNotifierProviderRef on AutoDisposeNotifierProviderRef<Post> {
  int get postId;
}

class _PostNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<PostNotifier, Post>
    with PostNotifierProviderRef {
  _PostNotifierProviderElement(super.provider);

  @override
  int get postId => (origin as PostNotifierProvider).postId;
}

String _$postsNotifierHash() => r'dd60c4d16b2dae785fc49fa1cd05ead2f41fd6fc';

@ProviderFor(PostsNotifier)
final postsNotifierProvider =
    AutoDisposeNotifierProvider<PostsNotifier, List<Post>>.internal(
  PostsNotifier.new,
  name: r'postsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postsNotifierHash,
  dependencies: <ProviderOrFamily>[
    userProvider,
  ],
  allTransitiveDependencies: <ProviderOrFamily>{
    userProvider,
    ...?userProvider.allTransitiveDependencies,
  },
);

typedef _$PostsNotifier = AutoDisposeNotifier<List<Post>>;
