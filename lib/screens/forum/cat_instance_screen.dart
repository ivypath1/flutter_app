import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ivy_path/providers/auth_provider.dart';
import 'package:ivy_path/screens/forum/add_topic_screen.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';
import 'package:ivy_path/services/forum_service.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Add this for StreamSubscription

class ForumCategoryPage extends StatefulWidget {
  final String categoryId;

  const ForumCategoryPage({super.key, required this.categoryId});

  @override
  State<ForumCategoryPage> createState() => _ForumCategoryPageState();
}

class _ForumCategoryPageState extends State<ForumCategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  late ForumService _forumService;
  
  ForumCategory? _category;
  List<ForumTopic> _topics = [];
  bool _loading = true;
  String? _errorMessage;
  StreamSubscription? _categorySubscription;
  StreamSubscription? _topicsSubscription;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.authData?.user;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not authenticated';
        _loading = false;
      });
      return;
    }
    
    _forumService = ForumService(auth: auth, user: user);
    _setupRealtimeListeners();
    _loadInitialData(); // Load initial data while setting up listeners
  }

  Future<void> _loadInitialData() async {
    try {
      final category = await _forumService.getCategory(widget.categoryId);
      final topics = await _forumService.getTopicsByCategory(widget.categoryId);
      
      if (mounted) {
        setState(() {
          _category = category;
          _topics = topics;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load initial data: $e';
          _loading = false;
        });
      }
    }
  }

  void _setupRealtimeListeners() {
    // Category listener
    _categorySubscription = _forumService.getCategoryStream(widget.categoryId).listen(
      (category) {
        if (mounted) {
          setState(() {
            _category = category;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load category updates: $e';
          });
        }
      },
    );

    // Topics listener
    _topicsSubscription = _forumService.getTopicsByCategoryStream(widget.categoryId).listen(
      (topics) {
        if (mounted) {
          setState(() {
            _topics = topics;
            if (_loading) _loading = false; // Only set loading to false if it was true
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load topic updates: $e';
            if (_loading) _loading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    _topicsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<ForumTopic> get filteredTopics {
    if (_searchController.text.isEmpty) return _topics;
    return _topics.where((topic) =>
      topic.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
      topic.tags.any((tag) => tag.toLowerCase().contains(_searchController.text.toLowerCase()))
    ).toList();
  }

  String _formatLastActivity(DateTime? date) {
    if (date == null) return 'just now';
    return '${DateFormat('MMM d').format(date)} at ${DateFormat('h:mm a').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    
    if (_loading && _category == null && _topics.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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

    if (_category == null) {
      return const Scaffold(body: Center(child: Text('Category not found')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_category!.name),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to new topic page
          Navigator.push(context, MaterialPageRoute(builder: (context) => NewTopicPage(categoryId: _category!.id)));
        },
        child: const Icon(Icons.add),
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
                        _category!.name,
                        style: TextStyle(
                          fontSize: mediaSetup(mediaWidth, sm: 20, md: 24, lg: 28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: mediaSetup(mediaWidth, sm: 2, md: 4, lg: 8)),
                      Text(
                        _category!.description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 16, lg: 24)),
                // ElevatedButton.icon(
                //   onPressed: () {
                //     // Start new topic
                //     Navigator.push(context, MaterialPageRoute(builder: (context) => NewTopicPage(categoryId: _category!.id)));
                //   },
                //   icon: const Icon(Icons.add, size: 16),
                //   label: const Text('New Topic'),
                // ),
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

  Widget _buildTopicCard(ForumTopic topic, double mediaWidth) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
        onTap: () {
          // Navigate to topic
          Navigator.pushNamed(context, 'topic/${topic.id}');
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
                    backgroundImage: topic.author.image != null 
                        ? NetworkImage(topic.author.image!) 
                        : null,
                    child: topic.author.image == null 
                        ? Text(topic.author.name[0])
                        : null,
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
                    '${topic.viewCount ?? 0} views',
                    style: TextStyle(
                      fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: mediaSetup(mediaWidth, sm: 12, md: 14, lg: 16)),
                  SizedBox(width: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8)),
                  Text(
                    _formatLastActivity(topic.updatedAt),
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