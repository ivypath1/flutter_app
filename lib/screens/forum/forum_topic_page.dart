import 'dart:async'; // Add this import for StreamSubscription

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ivy_path/providers/auth_provider.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';
import 'package:ivy_path/services/forum_service.dart';
import 'package:provider/provider.dart';

class ForumTopicPage extends StatefulWidget {
  final String topicId;

  const ForumTopicPage({super.key, required this.topicId});

  @override
  State<ForumTopicPage> createState() => _ForumTopicPageState();
}

class _ForumTopicPageState extends State<ForumTopicPage> {
  final TextEditingController _replyController = TextEditingController();
  late ForumService _forumService;
  
  ForumTopic? _topic;
  List<ForumReply> _replies = [];
  bool _loading = true;
  String? _error;
  bool _replying = false;
  StreamSubscription? _topicSubscription;
  StreamSubscription? _repliesSubscription;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.authData?.user;
    if (user == null) {
      setState(() {
        _error = 'User not authenticated';
        _loading = false;
      });
      return;
    }
    
    _forumService = ForumService(auth: auth, user: user);
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    // Topic listener
    _topicSubscription = _forumService.getTopicStream(widget.topicId).listen((topic) {
      if (mounted) {
        setState(() {
          _topic = topic;
          if (_replies.isNotEmpty) _loading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load topic: $e';
          _loading = false;
        });
      }
    });

    // Replies listener - fixed to use getRepliesForTopicStream
    _repliesSubscription = _forumService.getRepliesForTopicStream(widget.topicId).listen((replies) {
      if (mounted) {
        setState(() {
          _replies = replies;
          if (_topic != null) _loading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load replies: $e';
          _loading = false;
        });
      }
    });

    // Track initial view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forumService.trackTopicView(widget.topicId);
    });
  }

  @override
  void dispose() {
    _topicSubscription?.cancel();
    _repliesSubscription?.cancel();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _postReply() async {
    if (_replyController.text.trim().isEmpty) {
      setState(() => _error = 'Reply cannot be empty');
      return;
    }

    setState(() {
      _replying = true;
      _error = null;
    });
    
    try {
      await _forumService.postReply(
        topicId: widget.topicId,
        content: _replyController.text,
      );
      _replyController.clear();
    } catch (e) {
      setState(() => _error = 'Failed to post reply: $e');
    } finally {
      if (mounted) {
        setState(() => _replying = false);
      }
    }
  }

  Future<void> _likeTopic() async {
    if (_topic == null) return;
    try {
      await _forumService.likeTopic(_topic!.id);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to like topic: $e');
      }
    }
  }

  Future<void> _likeReply(String replyId) async {
    try {
      await _forumService.likeReply(replyId);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to like reply: $e');
      }
    }
  }

  bool _isLiked(Map<dynamic, dynamic> likes) {
    final userId = _forumService.user.id;
    return userId != null && likes.containsKey(userId);
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    
    if (_loading && _topic == null && _replies.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Forum'),
              ),
            ],
          ),
        ),
      );
    }

    if (_topic == null) {
      return const Scaffold(
        body: Center(child: Text('Topic not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_topic!.title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 24)),
        child: Column(
          children: [
            // Topic Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: mediaSetup(mediaWidth, sm: 16, md: 20, lg: 24),
                          backgroundImage: _topic!.author.image != null 
                              ? NetworkImage(_topic!.author.image!) 
                              : null,
                          child: _topic!.author.image == null 
                              ? Text(_topic!.author.name[0])
                              : null,
                        ),
                        SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _topic!.author.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (_topic!.author.role != null)
                                Text(
                                  _topic!.author.role!,
                                  style: TextStyle(
                                    fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                                    color: Colors.grey[600],
                                  ),
                                ),
                              if (_topic!.author.joinDate != null)
                                Text(
                                  _topic!.author.joinDate!,
                                  style: TextStyle(
                                    fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.access_time, size: mediaSetup(mediaWidth, sm: 14, md: 16, lg: 18)),
                        SizedBox(width: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8)),
                        Text(
                          DateFormat('MMM d, y').format(_topic!.createdAt),
                          style: TextStyle(
                            fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),

                    // Topic content
                    Text(
                      _topic!.content,
                      style: TextStyle(
                        fontSize: mediaSetup(mediaWidth, sm: 14, md: 16, lg: 18),
                      ),
                    ),
                    SizedBox(height: mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),

                    // Tags
                    Wrap(
                      spacing: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8),
                      children: _topic!.tags.map((tag) => Chip(
                        label: Text(tag),
                        labelStyle: TextStyle(
                          fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                        ),
                      )).toList(),
                    ),
                    SizedBox(height: mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),

                    // Actions
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.thumb_up,
                            color: _isLiked(_topic!.likes)
                                ? Theme.of(context).primaryColor 
                                : null,
                          ),
                          onPressed: _likeTopic,
                        ),
                        Text('${_topic!.likeCount}'),
                        SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            // Share functionality
                          },
                        ),
                        SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                        IconButton(
                          icon: const Icon(Icons.flag, color: Colors.red),
                          onPressed: () {
                            // Report functionality
                          },
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.message, size: mediaSetup(mediaWidth, sm: 14, md: 16, lg: 18)),
                            SizedBox(width: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8)),
                            Text('${_replies.length}'),
                          ],
                        ),
                        SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                        Row(
                          children: [
                            Icon(Icons.visibility, size: mediaSetup(mediaWidth, sm: 14, md: 16, lg: 18)),
                            SizedBox(width: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8)),
                            Text('${_topic!.viewCount ?? 0}'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),

            // Replies section
            Text(
              'Replies',
              style: TextStyle(
                fontSize: mediaSetup(mediaWidth, sm: 18, md: 22, lg: 24),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),

            if (_replies.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: mediaSetup(mediaWidth, sm: 24, md: 32, lg: 40)),
                  child: Text(
                    'No replies yet. Be the first to reply!',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ..._replies.map((reply) => _buildReplyCard(reply, mediaWidth)),

            // Reply form
            Card(
              child: Padding(
                padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Write a Reply',
                      style: TextStyle(
                        fontSize: mediaSetup(mediaWidth, sm: 16, md: 18, lg: 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                    TextField(
                      controller: _replyController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _replying ? null : _postReply,
                          icon: const Icon(Icons.send),
                          label: const Text('Post Reply'),
                        ),
                      ],
                    ),
                    if (_error != null)
                      Padding(
                        padding: EdgeInsets.only(top: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(ForumReply reply, double mediaWidth) {
    return Card(
      margin: EdgeInsets.only(bottom: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
      child: Padding(
        padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: mediaSetup(mediaWidth, sm: 16, md: 20, lg: 24),
                  backgroundImage: reply.author.image != null 
                      ? NetworkImage(reply.author.image!) 
                      : null,
                  child: reply.author.image == null 
                      ? Text(reply.author.name[0])
                      : null,
                ),
                SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.author.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (reply.author.role != null)
                        Text(
                          reply.author.role!,
                          style: TextStyle(
                            fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                            color: Colors.grey[600],
                          ),
                        ),
                      if (reply.author.joinDate != null)
                        Text(
                          reply.author.joinDate!,
                          style: TextStyle(
                            fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.access_time, size: mediaSetup(mediaWidth, sm: 14, md: 16, lg: 18)),
                SizedBox(width: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8)),
                Text(
                  DateFormat('MMM d, y').format(reply.createdAt),
                  style: TextStyle(
                    fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),

            // Reply content
            Text(
              reply.content,
              style: TextStyle(
                fontSize: mediaSetup(mediaWidth, sm: 14, md: 16, lg: 18),
              ),
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),

            // Actions
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.thumb_up,
                    color: _isLiked(reply.likes)
                        ? Theme.of(context).primaryColor 
                        : null,
                  ),
                  onPressed: () => _likeReply(reply.id),
                ),
                Text('${reply.likeCount}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flag, color: Colors.red),
                  onPressed: () {
                    // Report functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}