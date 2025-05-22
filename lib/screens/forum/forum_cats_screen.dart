import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Category> categories = [];
  List<Topic> topics = [];
  List<Reply> replies = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      categories = _generateDemoCategories();
      topics = _generateDemoTopics();
      replies = _generateDemoReplies();
      loading = false;
    });
  }

  List<Category> _generateDemoCategories() {
    return [
      Category(
        id: '1',
        name: 'Mathematics',
        icon: Icons.calculate,
        description: 'Discuss algebra, calculus, and other math topics',
        topics: 24,
        posts: 156,
      ),
      Category(
        id: '2',
        name: 'Science',
        icon: Icons.science,
        description: 'Physics, chemistry, biology discussions',
        topics: 18,
        posts: 112,
      ),
      Category(
        id: '3',
        name: 'Literature',
        icon: Icons.menu_book,
        description: 'Book discussions and analysis',
        topics: 15,
        posts: 89,
      ),
      Category(
        id: '4',
        name: 'History',
        icon: Icons.history,
        description: 'Historical events and discussions',
        topics: 12,
        posts: 67,
      ),
    ];
  }

  List<Topic> _generateDemoTopics() {
    return [
      Topic(
        id: '1',
        title: 'Help with quadratic equations',
        author: User(name: 'Alex Johnson', image: ''),
        category: '1',
        replies: 8,
        views: 124,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Topic(
        id: '2',
        title: 'Best books for calculus beginners',
        author: User(name: 'Maria Garcia', image: ''),
        category: '1',
        replies: 5,
        views: 98,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Topic(
        id: '3',
        title: 'Chemical reactions experiment',
        author: User(name: 'James Wilson', image: ''),
        category: '2',
        replies: 12,
        views: 156,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Topic(
        id: '4',
        title: 'World War II causes discussion',
        author: User(name: 'Sarah Lee', image: ''),
        category: '4',
        replies: 7,
        views: 87,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  List<Reply> _generateDemoReplies() {
    return [
      Reply(
        id: '1',
        content: 'I can help with that!',
        author: User(name: 'Teacher Mike', image: ''),
        topicId: '1',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Reply(
        id: '2',
        content: 'Try this book: Calculus Made Easy',
        author: User(name: 'Bookworm22', image: ''),
        topicId: '2',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Reply(
        id: '3',
        content: 'The experiment needs safety precautions',
        author: User(name: 'SciencePro', image: ''),
        topicId: '3',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  List<Activity> get recentActivity {
    final activities = <Activity>[];

    // Add topics as activities
    for (final topic in topics) {
      activities.add(Activity(
        id: 'topic-${topic.id}',
        type: ActivityType.newTopic,
        user: topic.author,
        topicTitle: topic.title,
        topicId: topic.id,
        timestamp: topic.createdAt,
      ));
    }

    // Add replies as activities
    for (final reply in replies) {
      final topic = topics.firstWhere((t) => t.id == reply.topicId);
      activities.add(Activity(
        id: 'reply-${reply.id}',
        type: ActivityType.reply,
        user: reply.author,
        topicTitle: topic.title,
        topicId: topic.id,
        timestamp: reply.createdAt,
      ));
    }

    // Sort by timestamp (newest first)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return activities.take(5).toList();
  }

  List<Category> get filteredCategories {
    if (_searchController.text.isEmpty) return categories;
    return categories.where((category) =>
      category.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
      category.description.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  List<Topic> get popularTopics {
    final sortedTopics = [...topics];
    sortedTopics.sort((a, b) => b.views.compareTo(a.views));
    return sortedTopics.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion Forums'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 16, lg: 24)),
            const Text(
              'Discussion Forums',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 2, md: 4, lg: 8)),
            Text(
              'Connect with fellow students and share knowledge',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
            
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search forums...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    mediaSetup(mediaWidth, sm: 6, md: 8, lg: 12)),
                ),
                contentPadding: EdgeInsets.all(
                  mediaSetup(mediaWidth, sm: 12, md: 14, lg: 16)),
              ),
              onChanged: (value) => setState(() {}),
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
            
            // Main content using mediaSetup for responsive layout
            _buildResponsiveContent(mediaWidth),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildResponsiveContent(double mediaWidth) {
    final mainContentWidth = mediaSetup(
      mediaWidth,
      sm: 1,
      md: 2,
      lg: 2,
    );

    final sidebarWidth = mediaSetup(
      mediaWidth,
      sm: 1,
      md: 1,
      lg: 1,
    );

    if (mediaWidth < 640) {
      // Mobile layout - single column
      return Column(
        children: [
          _buildCategoriesList(),
          SizedBox(height: mediaSetup(mediaWidth, sm: 16, md: 24)),
          _buildPopularTopicsCard(),
          SizedBox(height: mediaSetup(mediaWidth, sm: 16, md: 24)),
          _buildRecentActivityCard(),
        ],
      );
    } else {
      // Tablet/Desktop layout - two columns
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: mainContentWidth.toInt(),
            child: _buildCategoriesList(),
          ),
          SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 16, lg: 24)),
          Expanded(
            flex: sidebarWidth.toInt(),
            child: Column(
              children: [
                _buildPopularTopicsCard(),
                SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 16, lg: 24)),
                _buildRecentActivityCard(),
              ],
            ),
          ),
        ],
      );
    }
  }


  Widget _buildCategoriesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filteredCategories.isEmpty)
          const Center(
            child: Text('No categories found matching your search'),
          )
        else
          ...filteredCategories.map((category) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CategoryCard(category: category),
            ),
          ),
      ],
    );
  }

  Widget _buildPopularTopicsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Popular Topics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...popularTopics.map((topic) {
              final category = categories.firstWhere(
                (c) => c.id == topic.category,
                orElse: () => Category(id: '', name: '', icon: Icons.question_mark, description: '', topics: 0, posts: 0),
              );
              return PopularTopicItem(
                topic: topic,
                categoryName: category.name,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recentActivity.map((activity) => 
              RecentActivityItem(activity: activity),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to category
          Navigator.pushNamed(context, '');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.message, size: 16),
                            const SizedBox(width: 4),
                            Text('${category.topics} topics'),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            const Icon(Icons.people, size: 16),
                            const SizedBox(width: 4),
                            Text('${category.posts} posts'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentActivityItem extends StatelessWidget {
  final Activity activity;

  const RecentActivityItem({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(activity.user.name[0]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: activity.user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: activity.type == ActivityType.reply 
                            ? 'replied to' 
                            : 'created',
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: activity.topicTitle,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM d').format(activity.timestamp)} at ${DateFormat('h:mm a').format(activity.timestamp)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PopularTopicItem extends StatelessWidget {
  final Topic topic;
  final String categoryName;

  const PopularTopicItem({
    super.key,
    required this.topic,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigate to topic
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  topic.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Chip(
                  label: Text(categoryName),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.message, size: 16),
                    const SizedBox(width: 4),
                    Text('${topic.replies} replies'),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text('${DateFormat('MMM d').format(topic.updatedAt)}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Data models
class Category {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final int topics;
  final int posts;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.topics,
    required this.posts,
  });
}

class Topic {
  final String id;
  final String title;
  final User author;
  final String category;
  final int replies;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;

  Topic({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.replies,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
  });
}

class Reply {
  final String id;
  final String content;
  final User author;
  final String topicId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reply({
    required this.id,
    required this.content,
    required this.author,
    required this.topicId,
    required this.createdAt,
    required this.updatedAt,
  });
}

class User {
  final String name;
  final String image;

  User({required this.name, required this.image});
}

enum ActivityType { newTopic, reply }

class Activity {
  final String id;
  final ActivityType type;
  final User user;
  final String topicTitle;
  final String topicId;
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.type,
    required this.user,
    required this.topicTitle,
    required this.topicId,
    required this.timestamp,
  });
}