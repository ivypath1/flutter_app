import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ivy_path/providers/auth_provider.dart';
import 'package:ivy_path/services/forum_service.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';
import 'package:provider/provider.dart';

class NewTopicPage extends StatefulWidget {
  final String categoryId;

  const NewTopicPage({super.key, required this.categoryId});

  @override
  State<NewTopicPage> createState() => _NewTopicPageState();
}

class _NewTopicPageState extends State<NewTopicPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  late ForumService _forumService;

  List<String> _tags = [];
  bool _submitting = false;
  String? _errorMessage;
  final FocusNode _tagFocusNode = FocusNode();

  // Suggested tags based on category
  final Map<String, List<String>> _suggestedTags = {
    'mathematics': ["Algebra", "Calculus", "Geometry", "Trigonometry", "Statistics"],
    'english': ["Grammar", "Comprehension", "Vocabulary", "Literature", "Writing"],
    'physics': ["Mechanics", "Electricity", "Optics", "Thermodynamics", "Waves"],
    'chemistry': ["Organic", "Inorganic", "Physical", "Biochemistry", "Analytical"],
    'biology': ["Anatomy", "Genetics", "Ecology", "Microbiology", "Zoology"],
    'general': ["Help", "Question", "Discussion", "Advice", "Resources"],
  };

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.authData?.user;
    _forumService = ForumService(auth: auth, user: user as dynamic);
    
    // Set default tags based on category
    if (_suggestedTags.containsKey(widget.categoryId)) {
      _tags = _suggestedTags[widget.categoryId]!.sublist(0, 2);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tagToRemove) {
    setState(() {
      _tags.remove(tagToRemove);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await _forumService.createTopic(
        categoryId: widget.categoryId,
        title: _titleController.text,
        content: _contentController.text,
        tags: _tags,
      );
      
      if (mounted) {
        Navigator.pop(context); // Return to forum after successful post
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to post topic: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: EdgeInsets.only(bottom: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Category'),
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: mediaSetup(mediaWidth, sm: 16, md: 24)),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),

            // Header
            Padding(
              padding: EdgeInsets.only(bottom: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start New Topic',
                    style: TextStyle(
                      fontSize: mediaSetup(mediaWidth, sm: 24, md: 28, lg: 32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Share your questions or start a discussion',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),

            // Form Card
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 16, md: 20, lg: 24)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      Padding(
                        padding: EdgeInsets.only(bottom: mediaSetup(mediaWidth, sm: 16, md: 20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Title *',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: mediaSetup(mediaWidth, sm: 14, md: 16, lg: 18),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: 'Enter your topic title',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20),
                                  vertical: mediaSetup(mediaWidth, sm: 12, md: 14, lg: 16),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      // Tags Field
                      Padding(
                        padding: EdgeInsets.only(bottom: mediaSetup(mediaWidth, sm: 16, md: 20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tags',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: mediaSetup(mediaWidth, sm: 14, md: 16, lg: 18),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: EdgeInsets.all(
                                mediaSetup(mediaWidth, sm: 8, md: 10, lg: 12)),
                              child: Column(
                                children: [
                                  Wrap(
                                    spacing: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8),
                                    runSpacing: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8),
                                    children: _tags.map((tag) => Chip(
                                      label: Text(tag),
                                      deleteIcon: const Icon(Icons.close, size: 16),
                                      onDeleted: () => _removeTag(tag),
                                    )).toList(),
                                  ),
                                  TextField(
                                    controller: _tagController,
                                    focusNode: _tagFocusNode,
                                    decoration: InputDecoration(
                                      hintText: _tags.isEmpty ? 'Add tags...' : 'Add another tag',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: mediaSetup(mediaWidth, sm: 8, md: 10, lg: 12),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: _addTag,
                                      ),
                                    ),
                                    onSubmitted: (value) => _addTag(),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8)),
                              child: Text(
                                'Press enter to add a tag. Maximum 5 tags allowed.',
                                style: TextStyle(
                                  fontSize: mediaSetup(mediaWidth, sm: 10, md: 12, lg: 14),
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content Field
                      Padding(
                        padding: EdgeInsets.only(bottom: mediaSetup(mediaWidth, sm: 24, md: 32)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Content *',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: mediaSetup(mediaWidth, sm: 14, md: 16, lg: 18),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _contentController,
                              decoration: InputDecoration(
                                hintText: 'Write your post content...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20),
                                  vertical: mediaSetup(mediaWidth, sm: 12, md: 14, lg: 16),
                                ),
                              ),
                              maxLines: 10,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter content';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      // Form Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                right: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                            child: TextButton(
                              onPressed: _submitting ? null : () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _submitting || 
                                _titleController.text.isEmpty || 
                                _contentController.text.isEmpty
                              ? null 
                              : _submitForm,
                            icon: _submitting
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).colorScheme.onPrimary),
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(_submitting ? 'Posting...' : 'Post Topic'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}