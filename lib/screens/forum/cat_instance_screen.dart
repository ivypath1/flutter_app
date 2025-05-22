import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


double mediaSetup(double size, {double? sm, double? md, double? lg}) {
  if (size < 640) {
    return sm ?? md ?? lg ?? 1;
  } else if (size < 1024) {
    return md ?? lg ?? sm ?? 1;
  } else {
    return lg ?? md ?? sm ?? 1;
  }
}

class CategoryPage extends StatefulWidget {
  final String categoryId;

  const CategoryPage({super.key, required this.categoryId});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Topic> topics = [];
  Category? category;
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Mock category data
      final mockCategories = {
        '1': Category(id: '1', name: 'Mathematics', description: 'Discuss algebra, calculus, and other math topics'),
        '2': Category(id: '2', name: 'Science', description: 'Physics, chemistry, biology discussions'),
      };

      // Mock topics data
      final mockTopics = [
        Topic(
          id: '1',
          title: 'Help with quadratic equations',
          author: User(name: 'Alex Johnson', image: ''),
          categoryId: '1',
          replies: 8,
          viewCount: 124,
          isPinned: true,
          tags: ['algebra', 'math'],
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        Topic(
          id: '2',
          title: 'Calculus for beginners',
          author: User(name: 'Maria Garcia', image: ''),
          categoryId: '1',
          replies: 5,
          viewCount: 98,
          isPinned: false,
          tags: ['calculus'],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];

      setState(() {
        category = mockCategories[widget.categoryId];
        topics = mockTopics.where((t) => t.categoryId == widget.categoryId).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load data';
        loading = false;
      });
    }
  }

  List<Topic> get filteredTopics {
    if (_searchController.text.isEmpty) return topics;
    return topics.where((topic) =>
      topic.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
      topic.tags.any((tag) => tag.toLowerCase().contains(_searchController.text.toLowerCase()))
    ).toList();
  }

  String formatLastActivity(DateTime? date) {
    if (date == null) return 'just now';
    return '${DateFormat('MMM d').format(date)} at ${DateFormat('h:mm a').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    
    if (loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );
    }

    if (error.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Forums'),
              ),
            ],
          ),
        ),
      );
    }

    if (category == null) {
      return const Scaffold(body: Center(child: Text('Category not found')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(category!.name),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 16, lg: 24)),
            
            // Category header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category!.name,
                        style: TextStyle(
                          fontSize: mediaSetup(mediaWidth, sm: 20, md: 24, lg: 28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: mediaSetup(mediaWidth, sm: 2, md: 4, lg: 8)),
                      Text(
                        category!.description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 16, lg: 24)),
                ElevatedButton.icon(
                  onPressed: () {
                    // Start new topic
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Topic'),
                ),
              ],
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),

            // Search and filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search topics...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          mediaSetup(mediaWidth, sm: 6, md: 8, lg: 12)),
                      ),
                      contentPadding: EdgeInsets.all(
                        mediaSetup(mediaWidth, sm: 12, md: 14, lg: 16)),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                OutlinedButton.icon(
                  onPressed: () {
                    // Open filter
                  },
                  icon: const Icon(Icons.filter_alt_outlined, size: 16),
                  label: const Text('Filter'),
                ),
              ],
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),

            // Topics list
            if (filteredTopics.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: mediaSetup(mediaWidth, sm: 24, md: 48, lg: 64)),
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'No topics yet in this category. Be the first to start one!'
                        : 'No topics found matching your search',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTopics.length,
                separatorBuilder: (context, index) => SizedBox(
                  height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)
                ),
                itemBuilder: (context, index) {
                  final topic = filteredTopics[index];
                  return _buildTopicCard(topic, mediaWidth);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(Topic topic, double mediaWidth) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
        onTap: () {
          // Navigate to topic
        },
        child: Padding(
          padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: mediaSetup(mediaWidth, sm: 16, md: 20, lg: 24),
                    child: Text(topic.author.name[0]),
                  ),
                  SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                topic.title,
                                style: TextStyle(
                                  fontSize: mediaSetup(mediaWidth, sm: 14, md: 16, lg: 18),
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (topic.isPinned)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: mediaSetup(mediaWidth, sm: 4, md: 8, lg: 12)),
                                child: Chip(
                                  label: const Text('Pinned'),
                                  backgroundColor: Colors.grey[200],
                                  labelStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: mediaSetup(mediaWidth, sm: 4, md: 8, lg: 12)),
                        Wrap(
                          spacing: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8),
                          runSpacing: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8),
                          children: topic.tags.map((tag) => Chip(
                            label: Text(tag),
                            labelStyle: TextStyle(
                              fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14)),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
              Row(
                children: [
                  Icon(Icons.person, size: mediaSetup(mediaWidth, sm: 12, md: 14, lg: 16)),
                  SizedBox(width: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8)),
                  Text(
                    topic.author.name,
                    style: TextStyle(
                      fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                  Icon(Icons.message, size: mediaSetup(mediaWidth, sm: 12, md: 14, lg: 16)),
                  SizedBox(width: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8)),
                  Text(
                    '${topic.replies} replies',
                    style: TextStyle(
                      fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                  Icon(Icons.visibility, size: mediaSetup(mediaWidth, sm: 12, md: 14, lg: 16)),
                  SizedBox(width: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8)),
                  Text(
                    '${topic.viewCount} views',
                    style: TextStyle(
                      fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: mediaSetup(mediaWidth, sm: 12, md: 14, lg: 16)),
                  SizedBox(width: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8)),
                  Text(
                    formatLastActivity(topic.updatedAt),
                    style: TextStyle(
                      fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Data models
class Category {
  final String id;
  final String name;
  final String description;

  Category({
    required this.id,
    required this.name,
    required this.description,
  });
}

class Topic {
  final String id;
  final String title;
  final User author;
  final String categoryId;
  final int replies;
  final int viewCount;
  final bool isPinned;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Topic({
    required this.id,
    required this.title,
    required this.author,
    required this.categoryId,
    required this.replies,
    required this.viewCount,
    required this.isPinned,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
}

class User {
  final String name;
  final String image;

  User({required this.name, required this.image});
}