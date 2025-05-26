import 'package:flutter/material.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';
import 'package:ivy_path/widgets/layout_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Mock UTME', 'Practice', 'Forum', 'Materials'];
  
  // Mock user data
  final Map<String, dynamic> _userData = {
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'phone': '+234 802 123 4567',
    'image': 'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg',
    'program': 'Medicine & Surgery',
    'accountType': 'premium',
    'jambScore': 298,
    'oLevelGrades': [
      {'subject': 'English Language', 'grade': 'A1'},
      {'subject': 'Mathematics', 'grade': 'A1'},
      {'subject': 'Physics', 'grade': 'B2'},
      {'subject': 'Chemistry', 'grade': 'A1'},
      {'subject': 'Biology', 'grade': 'A1'},
    ],
  };

  final List<Map<String, dynamic>> _mockUTMEs = [
    {
      'id': 1,
      'title': 'Full Mock UTME - March 2025',
      'subjects': ['English', 'Mathematics', 'Physics', 'Chemistry'],
      'score': 85,
      'date': '2025-03-15',
      'duration': '120 minutes',
    },
    {
      'id': 2,
      'title': 'Full Mock UTME - February 2025',
      'subjects': ['English', 'Mathematics', 'Physics', 'Biology'],
      'score': 78,
      'date': '2025-02-28',
      'duration': '120 minutes',
    },
  ];

  final List<Map<String, dynamic>> _practiceSessions = [
    {
      'id': 3,
      'type': 'Practice',
      'subject': 'Mathematics',
      'score': 85,
      'date': '2025-03-14',
      'duration': '45 minutes',
    },
    {
      'id': 4,
      'type': 'Practice',
      'subject': 'Physics',
      'score': 78,
      'date': '2025-03-10',
      'duration': '30 minutes',
    },
  ];

  final List<Map<String, dynamic>> _forumTopics = [
    {
      'id': 1,
      'title': 'How to solve quadratic equations quickly?',
      'replies': 24,
      'lastActivity': '2 hours ago',
    },
    {
      'id': 2,
      'title': 'Understanding complex numbers',
      'replies': 18,
      'lastActivity': '4 hours ago',
    },
  ];

  final List<Map<String, dynamic>> _savedMaterials = [
    {
      'id': 1,
      'title': 'Calculus Study Guide',
      'type': 'PDF',
      'size': '2.4 MB',
      'savedDate': 'March 15, 2025',
    },
    {
      'id': 2,
      'title': 'Physics Formula Sheet',
      'type': 'PDF',
      'size': '1.8 MB',
      'savedDate': 'March 14, 2025',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDesktop = mediaWidth >= 1100;
    final isTablet = mediaWidth >= 600;
    
    return Scaffold(
      drawer: !isDesktop ? const AppDrawer(activeIndex: 2,) : null,
      body: Row(
        children: [
          if (isDesktop) const AppDrawer(activeIndex: 5),
          if (isTablet && !isDesktop) const IvyNavRail(),
          
          Expanded(
            child: CustomScrollView(
              // padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
              slivers: [
                IvyAppBar(
                  title: 'Practice Setup',
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
                                    backgroundImage: NetworkImage(_userData['image']),
                                    child: Text(_userData['name'][0]),
                                  ),
                                ],
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if(mediaWidth > 640) ...[
                                  CircleAvatar(
                                    radius: mediaSetup(mediaWidth, sm: 40, md: 48, lg: 56),
                                    backgroundImage: NetworkImage(_userData['image']),
                                    child: Text(_userData['name'][0]),
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
                                                _userData['name'],
                                                style: TextStyle(
                                                  fontSize: mediaSetup(mediaWidth, sm: 20, md: 24, lg: 28),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Chip(
                                                label: Text(
                                                  _userData['accountType'] == 'premium' 
                                                      ? 'Premium' 
                                                      : 'Demo',
                                                ),
                                                avatar: Icon(
                                                  _userData['accountType'] == 'premium'
                                                      ? Icons.shield
                                                      : Icons.lock,
                                                  size: 16,
                                                ),
                                                backgroundColor: _userData['accountType'] == 'premium'
                                                    ? theme.colorScheme.secondary
                                                    : theme.colorScheme.surfaceVariant,
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
                                                  Icon(Icons.email, size: 16),
                                                  SizedBox(width: 4),
                                                  Text(_userData['email']),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.phone, size: 16),
                                                  SizedBox(width: 4),
                                                  Text(_userData['phone']),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                          Wrap(
                                            children: [
                                              Icon(Icons.school, size: 16),
                                              SizedBox(width: 8),
                                              Text(
                                                _userData['program'],
                                                style: TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                              SizedBox(width: 16),
                                              Chip(
                                                label: Text('JAMB Score: ${_userData['jambScore']}'),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                          Wrap(
                                            spacing: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8),
                                            runSpacing: mediaSetup(mediaWidth, sm: 4, md: 6, lg: 8),
                                            children: _userData['oLevelGrades'].map<Widget>((grade) {
                                              return Chip(
                                                label: Text('${grade['subject']}: ${grade['grade']}'),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: mediaSetup(mediaWidth, sm: 16, md: 20, lg: 24)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        // Navigate to edit profile
                                      },
                                      icon: Icon(Icons.edit),
                                      label: Text('Edit Profile'),
                                    ),
                                    SizedBox(width: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                    IconButton(
                                      onPressed: () {
                                        // Navigate to settings
                                      },
                                      icon: Icon(Icons.settings),
                                    ),
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
                                  ListView.separated(
                                    itemCount: _mockUTMEs.length,
                                    separatorBuilder: (context, index) => SizedBox(
                                      height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                    itemBuilder: (context, index) {
                                      final mock = _mockUTMEs[index];
                                      return Card(
                                        child: InkWell(
                                          onTap: () {},
                                          child: Padding(
                                            padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                mock['title'],
                                                                style: TextStyle(fontWeight: FontWeight.w500),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 8),
                                                          Wrap(
                                                            spacing: 8,
                                                            children: mock['subjects'].map<Widget>((subject) {
                                                              return Padding(
                                                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                                                                child: Chip(
                                                                  label: Text(subject),
                                                                  backgroundColor: theme.colorScheme.surfaceVariant,
                                                                ),
                                                              );
                                                            }).toList(),
                                                          ),
                                                          SizedBox(height: 8),
                                                          Row(
                                                            children: [
                                                              Icon(Icons.calendar_today, size: 16),
                                                              SizedBox(width: 4),
                                                              Text(mock['date']),
                                                              SizedBox(width: 16),
                                                              Icon(Icons.timer, size: 16),
                                                              SizedBox(width: 4),
                                                              Text(mock['duration']),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      '${mock['score']}%',
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                        color: theme.primaryColor,
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
                                  ListView.separated(
                                    itemCount: _practiceSessions.length,
                                    separatorBuilder: (context, index) => SizedBox(
                                      height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                    itemBuilder: (context, index) {
                                      final practice = _practiceSessions[index];
                                      return Card(
                                        child: InkWell(
                                          onTap: () {},
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
                                                        Row(
                                                          children: [
                                                            Chip(
                                                              label: Text(practice['type']),
                                                              backgroundColor: theme.colorScheme.surfaceVariant,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              practice['subject'],
                                                              style: TextStyle(fontWeight: FontWeight.w500),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 8),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.calendar_today, size: 16),
                                                            SizedBox(width: 4),
                                                            Text(practice['date']),
                                                            SizedBox(width: 16),
                                                            Icon(Icons.timer, size: 16),
                                                            SizedBox(width: 4),
                                                            Text(practice['duration']),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      '${practice['score']}%',
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                        color: theme.primaryColor,
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
                                  ListView.separated(
                                    itemCount: _forumTopics.length,
                                    separatorBuilder: (context, index) => SizedBox(
                                      height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                    itemBuilder: (context, index) {
                                      final topic = _forumTopics[index];
                                      return Card(
                                        child: InkWell(
                                          onTap: () {},
                                          child: Padding(
                                            padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
                                            child: Column(
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      topic['title'],
                                                      style: TextStyle(fontWeight: FontWeight.w500),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.forum, size: 16),
                                                        SizedBox(width: 4),
                                                        Text('${topic['replies']} replies'),
                                                        SizedBox(width: 16),
                                                        Icon(Icons.timer, size: 16),
                                                        SizedBox(width: 4),
                                                        Text(topic['lastActivity']),
                                                      ],
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
                                  
                                  // Saved Materials Tab
                                  ListView.separated(
                                    itemCount: _savedMaterials.length,
                                    separatorBuilder: (context, index) => SizedBox(
                                      height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
                                    itemBuilder: (context, index) {
                                      final material = _savedMaterials[index];
                                      return Card(
                                        child: InkWell(
                                          onTap: () {},
                                          child: Padding(
                                            padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
                                            child: Column(
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.book, size: 16),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          material['title'],
                                                          style: TextStyle(fontWeight: FontWeight.w500),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 8),
                                                    Wrap(
                                                      children: [
                                                        SizedBox(width: 8),
                                                        Text(material['size']),
                                                        SizedBox(width: 16),
                                                        Icon(Icons.calendar_today, size: 16),
                                                        SizedBox(width: 4),
                                                        Text('Saved on ${material['savedDate']}'),
                                                      ],
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