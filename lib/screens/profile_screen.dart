import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ivy_path/models/result_model.dart';
import 'package:ivy_path/models/subject_model.dart';
import 'package:ivy_path/providers/auth_provider.dart';
import 'package:ivy_path/screens/materials/pdf_viewer_screen.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';
import 'package:ivy_path/widgets/layout_widget.dart';
import 'package:ivy_path/screens/session_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ivy_path/models/material_model.dart' as mat;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Mock UTME', 'Practice', 'Forum', 'Materials'];
  List<PracticeRecord> _practiceRecords = [];
  List<mat.Material> _materials = [];
  List<Subject> _subjects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadPracticeRecords();
  }

  Future<void> _loadPracticeRecords() async {
    try {
      final recordsBox = await Hive.openBox<PracticeRecord>('results');
      final subjectsBox = await Hive.openBox<Subject>('subjects');
      final materialsBox = await Hive.openBox<mat.Material>('materials');
      setState(() {
        _practiceRecords = recordsBox.values.toList();
        _subjects = subjectsBox.values.toList();
        _materials = materialsBox.values.toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<PracticeRecord> get _mockRecords => _practiceRecords.where((r) => r.mode == 'mock').toList();
  List<PracticeRecord> get _practiceSessionRecords => _practiceRecords.where((r) => r.mode == 'practice').toList();

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDesktop = mediaWidth >= 1100;
    final isTablet = mediaWidth >= 600;
    final auth = context.watch<AuthProvider>();
    final user = auth.authData?.user;
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your profile'),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text('Error: $_error'),
        ),
      );
    }
    
    return Scaffold(
      drawer: !isDesktop ? const AppDrawer(activeIndex: 7,) : null,
      body: Row(
        children: [
          if (isDesktop) const AppDrawer(activeIndex: 7),
          if (isTablet && !isDesktop) const IvyNavRail(),
          
          Expanded(
            child: CustomScrollView(
              slivers: [
                IvyAppBar(
                  title: 'Profile',
                  showMenuButton: !isDesktop,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Overview Card
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 16, md: 20, lg: 24)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if(mediaWidth < 640) ...[
                                  CircleAvatar(
                                    radius: mediaSetup(mediaWidth, sm: 40, md: 48, lg: 56),
                                    backgroundImage: NetworkImage(
                                      user.image ??
                                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.firstName)}&background=0D8ABC&color=fff'
                                    ),
                                    child: Text(user.firstName[0]),
                                  ),
                                ],
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if(mediaWidth > 640) ...[
                                      CircleAvatar(
                                        radius: mediaSetup(mediaWidth, sm: 40, md: 48, lg: 56),
                                        backgroundImage: NetworkImage(
                                            user.image ??
                                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.firstName)}&background=0D8ABC&color=fff'
                                        ),
                                        child: Text(user.firstName[0]),
                                      ),
                                    ],
                                    SizedBox(width: mediaSetup(mediaWidth, sm: 16, md: 20, lg: 24)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${user.firstName} ${user.lastName}',
                                                style: TextStyle(
                                                  fontSize: mediaSetup(mediaWidth, sm: 20, md: 24, lg: 28),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Chip(
                                                label: Text(user.type),
                                                avatar: Icon(
                                                  user.type == 'premium'
                                                      ? Icons.shield
                                                      : Icons.lock,
                                                  size: 16,
                                                ),
                                                backgroundColor: user.type == 'premium'
                                                    ? theme.colorScheme.secondary
                                                    : theme.colorScheme.surfaceContainerHigh,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                          Wrap(
                                            spacing: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16),
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.email, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(user.email),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.phone, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(user.phone ?? 'N/A'),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                          Wrap(
                                            children: [
                                              const Icon(Icons.school, size: 16),
                                              const SizedBox(width: 8),
                                              Text(
                                                user.program,
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: mediaSetup(mediaWidth, sm: 16, md: 20, lg: 24)),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // OutlinedButton.icon(
                                    //   onPressed: () {
                                    //     // Navigate to edit profile
                                    //   },
                                    //   icon: const Icon(Icons.edit),
                                    //   label: const Text('Edit Profile'),
                                    // ),
                                    // SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                    // IconButton(
                                    //   onPressed: () {
                                    //     // Navigate to settings
                                    //   },
                                    //   icon: const Icon(Icons.settings),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
                                  
                        // Tabs Section
                        Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              tabs: _tabs.map((tab) {
                                IconData icon;
                                switch (tab) {
                                  case 'Mock UTME':
                                    icon = Icons.emoji_events;
                                    break;
                                  case 'Practice':
                                    icon = Icons.article;
                                    break;
                                  case 'Forum':
                                    icon = Icons.forum;
                                    break;
                                  case 'Materials':
                                    icon = Icons.bookmark;
                                    break;
                                  default:
                                    icon = Icons.category;
                                }
                                return Tab(
                                  icon: Icon(icon, size: 16),
                                  text: tab,
                                );
                              }).toList(),
                            ),
                            SizedBox(
                              height: 500, // Adjust based on content
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Mock UTME Tab
                                  _mockRecords.isEmpty
                                      ? const Center(child: Text('No mock exams taken yet'))
                                      : ListView.separated(
                                          itemCount: _mockRecords.length,
                                          separatorBuilder: (context, index) => SizedBox(
                                            height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                          itemBuilder: (context, index) {
                                            final record = _mockRecords[index];
                                            final avgScore = record.results.fold(0.0, (sum, r) => sum + r.score) / record.results.length;
                                            
                                            return Card(
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => SessionPage(
                                                    mode: record.mode, 
                                                    duration: record.duration, 
                                                    subjects: record.results
                                                    .where((results) => _subjects.any((subject) => subject.id == results.subjectId))
                                                    .map((results) {
                                                      final subject = _subjects.firstWhere((subject) => subject.id == results.subjectId);
                                                      return {
                                                        "id": results.subjectId,
                                                        "name": subject.name,
                                                      };
                                                    }).toList(),
                                                    fromRecord: record,
                                                  )));
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              const Text(
                                                                'Mock UTME Session',
                                                                style: TextStyle(fontWeight: FontWeight.w500),
                                                              ),
                                                              const SizedBox(height: 8),
                                                              Row(
                                                                children: [
                                                                  const Icon(Icons.calendar_today, size: 16),
                                                                  const SizedBox(width: 4),
                                                                  Text(DateFormat('MMM d, y').format(record.timestamp)),
                                                                  const SizedBox(width: 16),
                                                                  const Icon(Icons.timer, size: 16),
                                                                  const SizedBox(width: 4),
                                                                  Text('${record.duration} mins'),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          Text(
                                                            '${avgScore.toStringAsFixed(1)}%',
                                                            style: const TextStyle(
                                                              fontSize: 24,
                                                              fontWeight: FontWeight.bold,
                                                              // color: theme.primaryColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                  
                                  // Practice Sessions Tab
                                  _practiceSessionRecords.isEmpty
                                      ? const Center(child: Text('No practice sessions yet'))
                                      : ListView.separated(
                                          itemCount: _practiceSessionRecords.length,
                                          separatorBuilder: (context, index) => SizedBox(
                                            height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                          itemBuilder: (context, index) {
                                            final record = _practiceSessionRecords[index];
                                            final avgScore = record.results.fold(0.0, (sum, r) => sum + r.score) / record.results.length;
                                            
                                            return Card(
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => SessionPage(
                                                    mode: record.mode, 
                                                    duration: record.duration, 
                                                    subjects: record.results.map((results) => <String, dynamic>{
                                                      "id": results.subjectId,
                                                      "name": _subjects.firstWhere((subject) => subject.id == results.subjectId)?.name,
                                                      }).toList(),
                                                    fromRecord: record,
                                                  )));
                                                  
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              const Text(
                                                                'Practice Session',
                                                                style: TextStyle(fontWeight: FontWeight.w500),
                                                              ),
                                                              const SizedBox(height: 8),
                                                              Row(
                                                                children: [
                                                                  const Icon(Icons.calendar_today, size: 16),
                                                                  const SizedBox(width: 4),
                                                                  Text(DateFormat('MMM d, y').format(record.timestamp)),
                                                                  const SizedBox(width: 16),
                                                                  const Icon(Icons.timer, size: 16),
                                                                  const SizedBox(width: 4),
                                                                  Text('${record.duration} mins'),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          Text(
                                                            '${avgScore.toStringAsFixed(1)}%',
                                                            style: const TextStyle(
                                                              fontSize: 24,
                                                              fontWeight: FontWeight.bold,
                                                              // color: theme.primaryColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                  
                                  // Forum Topics Tab
                                  const Center(child: Text('Forum activity coming soon')),
                                  

                                  // Saved Materials Tab
                                  _materials.isEmpty
                                      ? const Center(child: Text('No saved materials'))
                                      : ListView.separated(
                                        itemCount: _materials.length,
                                        separatorBuilder: (context, index) => SizedBox(
                                          height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                        itemBuilder: (context, index) {
                                          final material = _materials[index];
                                          return Card(
                                            child: InkWell(
                                              onTap: () {
                                                // Handle material tap
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => PDFViewerScreen(
                                                      source: '${material.id}',
                                                      title: material.title,
                                                      isUrl: false,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.book, size: 16),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          material.title,
                                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Wrap(
                                                      children: [
                                                        Text('${material.fileSize} MB'),
                                                        const SizedBox(width: 16),
                                                        const Icon(Icons.calendar_today, size: 16),
                                                        const SizedBox(width: 4),
                                                        Text('Saved on ${DateFormat('MMM d, y').format(material.uploadedDate)}'),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
}