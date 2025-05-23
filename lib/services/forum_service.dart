import 'package:firebase_database/firebase_database.dart';

class ForumService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<List<ForumCategory>> getCategories() async {
    try {
      final snapshot = await _database.child('categories').get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries.map((entry) {
          final categoryData = Map<String, dynamic>.from(entry.value as Map);
          return ForumCategory(
            id: entry.key,
            name: categoryData['name'] as String,
            description: categoryData['description'] as String,
            icon: categoryData['icon'] as String,
            topics: categoryData['topics'] as int,
            posts: categoryData['posts'] as int,
          );
        }).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<ForumTopic>> getTopics(String categoryId) async {
    try {
      final snapshot = await _database
          .child('topics')
          .orderByChild('categoryId')
          .equalTo(categoryId)
          .get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries.map((entry) {
          final topicData = Map<String, dynamic>.from(entry.value as Map);
          return ForumTopic(
            id: entry.key,
            title: topicData['title'] as String,
            content: topicData['content'] as String,
            authorId: topicData['authorId'] as String,
            categoryId: topicData['categoryId'] as String,
            createdAt: DateTime.parse(topicData['createdAt'] as String),
            updatedAt: DateTime.parse(topicData['updatedAt'] as String),
            replies: topicData['replies'] as int? ?? 0,
            views: topicData['views'] as int? ?? 0,
          );
        }).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to load topics: $e');
    }
  }

  Future<List<ForumReply>> getReplies(String topicId) async {
    try {
      final snapshot = await _database
          .child('replies')
          .orderByChild('topicId')
          .equalTo(topicId)
          .get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries.map((entry) {
          final replyData = Map<String, dynamic>.from(entry.value as Map);
          return ForumReply(
            id: entry.key,
            content: replyData['content'] as String,
            authorId: replyData['authorId'] as String,
            topicId: replyData['topicId'] as String,
            createdAt: DateTime.parse(replyData['createdAt'] as String),
            updatedAt: DateTime.parse(replyData['updatedAt'] as String),
          );
        }).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to load replies: $e');
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
}

class ForumTopic {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int replies;
  final int views;

  ForumTopic({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    required this.replies,
    required this.views,
  });
}

class ForumReply {
  final String id;
  final String content;
  final String authorId;
  final String topicId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ForumReply({
    required this.id,
    required this.content,
    required this.authorId,
    required this.topicId,
    required this.createdAt,
    required this.updatedAt,
  });
}