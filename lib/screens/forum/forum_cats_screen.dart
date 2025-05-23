import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ivy_path/services/forum_service.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _searchController = TextEditingController();
  final ForumService _forumService = ForumService();
  List<ForumCategory> categories = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final data = await _forumService.getCategories();
      setState(() {
        categories = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  List<ForumCategory> get filteredCategories {
    if (_searchController.text.isEmpty) return categories;
    return categories.where((category) =>
      category.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
      category.description.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
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

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
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
          Navigator.pushNamed(context, '/forum/${category.id}');
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
                child: Icon(Icons.forum, color: Colors.blue),
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