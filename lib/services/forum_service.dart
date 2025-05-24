import 'package:firebase_database/firebase_database.dart';
import 'package:ivy_path/models/user_model.dart' as user_model;

class ForumService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final dynamic auth;
  final user_model.User user;

  ForumService({
    required this.auth,
    required this.user,
  });

  // Real-time listeners
  Stream<List<ForumCategory>> getCategoriesStream() {
    return _database.child('categories').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((entry) {
        return ForumCategory(
          id: entry.key as String,
          name: entry.value['name'] as String,
          description: entry.value['description'] as String,
          icon: entry.value['icon'] as String,
          topics: (entry.value['topics'] as int?) ?? 0,
          posts: (entry.value['posts'] as int?) ?? 0,
        );
      }).toList();
    });
  }

  Stream<ForumCategory?> getCategoryStream(String categoryId) {
    return _database.child('categories').child(categoryId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return ForumCategory.fromMap({
        'id': categoryId,
        ...data,
      });
    });
  }

  Future<void> createTopic({
    required String categoryId,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    try {
      final userId = user.id;
      if (userId == null) throw Exception('User not authenticated');

      final newTopicRef = _database.child('topics').push();

      final newTopic = {
        'title': title,
        'content': content,
        'category': categoryId,
        'tags': tags,
        'author': {
          'name': "${user.firstName} ${user.lastName}",
          'image': user.email,
          'role': 'Student',
          'joinDate': 'Member since ${user.dateJoined}',
          'uid': userId,
          'isVerified': false,
        },
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'replies': 0,
        'viewCount': 0,
        'isPinned': false,
        'likeCount': 0,
        'likes': {},
      };

      await newTopicRef.set(newTopic);

      // Update category's topic count
      await _database.child('categories/$categoryId').update({
        'topics': ServerValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to create topic: $e');
    }
  }

  Stream<List<ForumTopic>> getTopicsStream() {
    return _database.child('topics').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((entry) {
        final topicData = entry.value as Map<dynamic, dynamic>;
        return ForumTopic(
          id: entry.key as String,
          title: topicData['title'] as String,
          content: topicData['content'] as String,
          author: User.fromMap(Map<String, dynamic>.from(topicData['author'])),
          categoryId: topicData['category'] as String,
          createdAt: DateTime.parse(topicData['createdAt'] as String),
          updatedAt: DateTime.parse(
              topicData['updatedAt'] as String? ?? topicData['createdAt'] as String),
          replies: (topicData['replies'] as int?) ?? 0,
          viewCount: (topicData['viewCount'] as int?) ?? 0,
          isPinned: (topicData['isPinned'] as bool?) ?? false,
          likes: (topicData['likes'] as Map<dynamic, dynamic>?) ?? {},
          likeCount: (topicData['likeCount'] as int?) ?? 0,
          tags: List<String>.from(topicData['tags'] ?? []),
        );
      }).toList();
    });
  }

  Stream<ForumTopic?> getTopicStream(String topicId) {
    return _database.child('topics').child(topicId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return ForumTopic.fromMap({
        'id': topicId,
        ...data,
      });
    });
  }

  Stream<List<ForumTopic>> getTopicsByCategoryStream(String categoryId) {
    return _database.child('topics')
        .orderByChild('category')
        .equalTo(categoryId)
        .onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((entry) {
        return ForumTopic.fromMap({
          'id': entry.key,
          ...entry.value as Map<dynamic, dynamic>,
        });
      }).toList();
    });
  }

  Stream<List<ForumReply>> getRepliesStream() {
    return _database.child('replies').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((entry) {
        final replyData = entry.value as Map<dynamic, dynamic>;
        return ForumReply(
          id: entry.key as String,
          content: replyData['content'] as String,
          author: User.fromMap(Map<String, dynamic>.from(replyData['author'])),
          topicId: replyData['topicId'] as String,
          createdAt: DateTime.parse(replyData['createdAt'] as String),
          likeCount: (replyData['likeCount'] as int?) ?? 0,
          likes: (replyData['likes'] as dynamic) ?? {},
        );
      }).toList();
    });
  }

  Stream<List<ForumReply>> getRepliesForTopicStream(String topicId) {
    return _database.child('replies')
        .orderByChild('topicId')
        .equalTo(topicId)
        .onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((entry) {
        return ForumReply.fromMap({
          'id': entry.key,
          ...entry.value as Map<dynamic, dynamic>,
        });
      }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
  }

  // One-time fetchers (kept for compatibility)
  Future<List<ForumCategory>> getCategories() async {
    try {
      final snapshot = await _database.child('categories').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          return ForumCategory(
            id: entry.key as String,
            name: entry.value['name'] as String,
            description: entry.value['description'] as String,
            icon: entry.value['icon'] as String,
            topics: (entry.value['topics'] as int?) ?? 0,
            posts: (entry.value['posts'] as int?) ?? 0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<ForumCategory?> getCategory(String categoryId) async {
    try {
      final snapshot = await _database.child('categories').child(categoryId).get();
      if (snapshot.exists) {
        return ForumCategory.fromMap({
          'id': categoryId,
          ...snapshot.value as Map<dynamic, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load category: $e');
    }
  }

  Future<List<ForumTopic>> getTopics() async {
    try {
      final snapshot = await _database.child('topics').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          final topicData = entry.value as Map<dynamic, dynamic>;
          return ForumTopic(
            id: entry.key as String,
            title: topicData['title'] as String,
            content: topicData['content'] as String,
            author: User.fromMap(Map<String, dynamic>.from(topicData['author'])),
            categoryId: topicData['category'] as String,
            createdAt: DateTime.parse(topicData['createdAt'] as String),
            updatedAt: DateTime.parse(
                topicData['updatedAt'] as String? ?? topicData['createdAt'] as String),
            replies: (topicData['replies'] as int?) ?? 0,
            viewCount: (topicData['viewCount'] as int?) ?? 0,
            isPinned: (topicData['isPinned'] as bool?) ?? false,
            likes: (topicData['likes'] as Map<dynamic, dynamic>?) ?? {},
            likeCount: (topicData['likeCount'] as int?) ?? 0,
            tags: List<String>.from(topicData['tags'] ?? []),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print(e);
      throw Exception('Failed to load topics: $e');
    }
  }

  Future<ForumTopic?> getTopic(String topicId) async {
    try {
      final snapshot = await _database.child('topics').child(topicId).get();
      if (snapshot.exists) {
        return ForumTopic.fromMap({
          'id': topicId,
          ...snapshot.value as Map<dynamic, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load topic: $e');
    }
  }

  Future<List<ForumTopic>> getTopicsByCategory(String categoryId) async {
    try {
      final query = _database.child('topics').orderByChild('category').equalTo(categoryId);
      final snapshot = await query.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          return ForumTopic.fromMap({
            'id': entry.key,
            ...entry.value as Map<dynamic, dynamic>,
          });
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load topics: $e');
    }
  }

  Future<List<ForumReply>> getReplies() async {
    try {
      final snapshot = await _database.child('replies').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          final replyData = entry.value as Map<dynamic, dynamic>;
          return ForumReply(
            id: entry.key as String,
            content: replyData['content'] as String,
            author: User.fromMap(Map<String, dynamic>.from(replyData['author'])),
            topicId: replyData['topicId'] as String,
            createdAt: DateTime.parse(replyData['createdAt'] as String),
            likeCount: (replyData['likeCount'] as int?) ?? 0,
            likes: (replyData['likes'] as dynamic) ?? {},
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load replies: $e');
    }
  }

  Future<List<ForumReply>> getRepliesForTopic(String topicId) async {
    try {
      final query = _database.child('replies').orderByChild('topicId').equalTo(topicId);
      final snapshot = await query.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          return ForumReply.fromMap({
            'id': entry.key,
            ...entry.value as Map<dynamic, dynamic>,
          });
        }).toList();
      }
      return [];
    } catch (e) {
      print(e);
      throw Exception('Failed to load replies: $e');
    }
  }

  Future<void> trackTopicView(String topicId) async {
    try {
      final userId = user.id;
      if (userId == null) return;

      final userViewRef = _database.child('topics/$topicId/views/$userId');
      final snapshot = await userViewRef.get();

      if (!snapshot.exists) {
        await _database.child('topics/$topicId').update({
          'views/$userId': true,
          'viewCount': ServerValue.increment(1),
        });
      }
    } catch (e) {
      print('Error tracking view: $e');
    }
  }

  Future<void> postReply({
    required String topicId,
    required String content,
  }) async {
    try {
      final repliesRef = _database.child('replies');
      final newReplyRef = repliesRef.push();
      String isoString = "2025-05-12T16:12:26Z";
      DateTime dateTime = DateTime.parse(isoString).toLocal();

      final newReply = {
        'content': content,
        'author': {
          'name': "${user.firstName} ${user.lastName}",
          'image': user.image,
          'role': 'Student',
          'joinDate': 'Member since ${dateTime.month}/${dateTime.day}/${dateTime.year}',
          'uid': user.id,
          'isVerified': false,
        },
        'createdAt': DateTime.now().toIso8601String(),
        'likes': {},
        'likeCount': 0,
        'topicId': topicId,
      };

      await newReplyRef.set(newReply);

      // Update topic's reply count and last updated time
      await _database.child('topics/$topicId').update({
        'replies': ServerValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to post reply: $e');
    }
  }

  Future<void> likeTopic(String topicId) async {
    try {
      final userId = user.id;
      if (userId == null) throw Exception('User not authenticated');

      final userLikeRef = _database.child('topics/$topicId/likes/$userId');
      final snapshot = await userLikeRef.get();

      final Map<String, dynamic> updates = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (snapshot.exists) {
        updates['likes/$userId'] = null;
        updates['likeCount'] = ServerValue.increment(-1);
      } else {
        updates['likes/$userId'] = true;
        updates['likeCount'] = ServerValue.increment(1);
      }

      await _database.child('topics/$topicId').update(updates);
    } catch (e) {
      throw Exception('Failed to like topic: $e');
    }
  }

  Future<void> likeReply(String replyId) async {
    try {
      final userId = user.id;
      if (userId == null) throw Exception('User not authenticated');

      final userLikeRef = _database.child('replies/$replyId/likes/$userId');
      final snapshot = await userLikeRef.get();

      final Map<String, dynamic> updates = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (snapshot.exists) {
        updates['likes/$userId'] = null;
        updates['likeCount'] = ServerValue.increment(-1);
      } else {
        updates['likes/$userId'] = true;
        updates['likeCount'] = ServerValue.increment(1);
      }

      await _database.child('replies/$replyId').update(updates);
    } catch (e) {
      throw Exception('Failed to like reply: $e');
    }
  }
}

class ForumCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int topics;
  final int posts;

  ForumCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.topics,
    required this.posts,
  });

  factory ForumCategory.fromMap(Map<String, dynamic> map) {
    return ForumCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      topics: (map['topics'] as int?) ?? 0,
      posts: (map['posts'] as int?) ?? 0,
    );
  }
}

class ForumTopic {
  final String id;
  final String title;
  final String content;
  final User author;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int replies;
  final int? viewCount;
  final bool isPinned;
  final Map<dynamic, dynamic> likes;
  final int likeCount;
  final List<String> tags;

  ForumTopic({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    required this.replies,
    this.viewCount,
    required this.isPinned,
    required this.likeCount,
    required this.tags,
    required this.likes,
  });

  factory ForumTopic.fromMap(Map<String, dynamic> map) {
    return ForumTopic(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      author: User.fromMap(Map<String, dynamic>.from(map['author'])),
      categoryId: map['category'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String? ?? map['createdAt'] as String),
      replies: (map['replies'] as int?) ?? 0,
      viewCount: (map['viewCount'] as int?) ?? 0,
      isPinned: (map['isPinned'] as bool?) ?? false,
      likeCount: (map['likeCount'] as int?) ?? 0,
      likes: (map['likes'] as dynamic) ?? {},
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}

class ForumReply {
  final String id;
  final String content;
  final User author;
  final String topicId;
  final DateTime createdAt;
  final int likeCount;
  final Map<dynamic, dynamic> likes;

  ForumReply({
    required this.id,
    required this.content,
    required this.author,
    required this.topicId,
    required this.createdAt,
    required this.likeCount,
    required this.likes,
  });

  factory ForumReply.fromMap(Map<String, dynamic> map) {
    return ForumReply(
      id: map["id"],
      content: map['content'] as String,
      author: User.fromMap(Map<String, dynamic>.from(map['author'])),
      topicId: map['topicId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      likeCount: (map['likeCount'] as int?) ?? 0,
      likes: (map['likes'] as dynamic) ?? {},
    );
  }
}

class User {
  final String? uid;
  final String name;
  final String? image;
  final String? role;
  final String? joinDate;
  final bool? isVerified;
  final String? email;

  User({
    this.uid,
    required this.name,
    this.image,
    this.role,
    this.joinDate,
    this.isVerified,
    this.email,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid']?.toString(),
      name: map['name'] as String,
      image: map['image'] as String?,
      role: map['role'] as String?,
      joinDate: map['joinDate'] as String?,
      isVerified: map['isVerified'] as bool?,
      email: map['email'] as String?,
    );
  }
}