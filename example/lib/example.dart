import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'example.gen.dart';

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
  return User(id: 11, username: 'Pantelis');
}

// Keep alive provider
@Riverpod(keepAlive: true)
Future<List<User>> users(UsersRef ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return [
    User(id: 11, username: 'Pantelis'),
  ];
}

class Post {
  Post({
    required this.id,
  });

  final int id;
}

@riverpod
class PostNotifier extends _$PostNotifier {
  @override
  Post build(int postId) {
    // Family provider
    return Post(id: postId);
  }
}

// Provider with dependencies
@Riverpod(dependencies: [user])
class PostsNotifier extends _$PostsNotifier {
  @override
  List<Post> build() {
    // get posts for user id
    ref.watch(userProvider).id;
    return [Post(id: 1)];
  }
}
