import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ivy_path/providers/auth_provider.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';
import 'package:ivy_path/services/forum_service.dart';
import 'package:ivy_path/widgets/layout_widget.dart';
import 'package:provider/provider.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _searchController = TextEditingController();
  late ForumService _forumService;
  
  List<ForumCategory> _categories = [];
  List<ForumTopic> _topics = [];
  List<ForumReply> _replies = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.authData?.user;
    _forumService = ForumService(auth: auth, user: user as dynamic);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _forumService.getCategories();
      final topics = await _forumService.getTopics();
      final replies = await _forumService.getReplies();

      setState(() {
        _categories = categories;
        _topics = topics;
        _replies = replies;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load forum data: $e';
        _loading = false;
      });
    }
  }

  List<Activity> get recentActivity {
    final activities = <Activity>[];

    // Add topics as activities
    for (final topic in _topics) {
      activities.add(Activity(
        id: topic.id,
        type: ActivityType.newTopic,
        user: topic.author,
        topicTitle: topic.title,
        topicId: topic.id,
        timestamp: topic.createdAt,
      ));
    }

    // Add replies as activities
    for (final reply in _replies) {
      final topic = _topics.firstWhere((t) => t.id == reply.topicId);
      activities.add(Activity(
        id: reply.id,
        type: ActivityType.reply,
        user: reply.author,
        topicTitle: topic.title,
        topicId: topic.id,
        timestamp: reply.createdAt,
      ));
    }

    // Sort by timestamp (newest first)
    activities.sort((a, b) {
      final timeComparison = b.timestamp.compareTo(a.timestamp);
      if (timeComparison != 0) return timeComparison;
      return a.id.compareTo(b.id); // secondary sort for consistency
    });
    
    return activities.take(5).toList();
  }

  List<ForumCategory> get filteredCategories {
    if (_searchController.text.isEmpty) return _categories;
    return _categories.where((category) =>
      category.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
      category.description.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  List<ForumTopic> get popularTopics {
    if (_topics.length <= 5) return _topics;
    final sortedTopics = [..._topics];
    sortedTopics.sort((a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0));
    return sortedTopics.take(5).toList();
  }


  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isDesktop = mediaWidth >= 1100;
    final isTablet = mediaWidth >= 600;
    
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(_errorMessage!),
        ),
      );
    }

    return Scaffold(
      drawer: !isDesktop ? const AppDrawer(activeIndex: 5,) : null,
      // appBar: AppBar(
      //   title: const Text('Discussion Forums'),
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to new topic page
        },
        child: const Icon(Icons.add),
      ),
      body: Row(
        children: [
          if (isDesktop) const AppDrawer(activeIndex: 5),
          if (isTablet && !isDesktop)
            const IvyNavRail(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                IvyAppBar(
                  title: 'Discussion Forums',
                  showMenuButton: !isDesktop,
                ),
                SliverToBoxAdapter(
                  child: Padding(
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
                ),
              ]
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveContent(double mediaWidth) {
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
      // Desktop layout - two columns
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildCategoriesList(),
          ),
          SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 16, lg: 24)),
          Expanded(
            flex: 1,
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
              final category = _categories.firstWhere(
                (c) => c.id == topic.categoryId,
                orElse: () => ForumCategory(
                  id: '', 
                  name: 'Unknown', 
                  description: '', 
                  icon: '', 
                  topics: 0, 
                  posts: 0
                ),
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
  final ForumCategory category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to category
          Navigator.pushNamed(context, 'forum/${category.id}');
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
                child: Icon(_getIconData(category.icon)),
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

  static const _iconMap = {
    'messagesquare': Icons.message,
    'calculate': Icons.calculate,
    'science': Icons.science,
    'history': Icons.history,
    'book': Icons.menu_book,
  };

  IconData _getIconData(String iconName) {
    return _iconMap[iconName.toLowerCase()] ?? Icons.forum;
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
  final ForumTopic topic;
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
