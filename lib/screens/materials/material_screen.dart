import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:ivy_path/widgets/layout_widget.dart';

double mediaSetup(double size, {double? sm, double? md, double? lg}) {
  if (size < 640) {
    return sm ?? md ?? lg ?? 1;
  } else if (size < 1024) {
    return md ?? lg ?? sm ?? 1;
  } else {
    return lg ?? md ?? sm ?? 1;
  }
}

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  List<Material> materials = [];
  List<Material> filteredMaterials = [];
  bool loading = true;
  String? error;

  // Filter and sort states
  String searchQuery = "";
  dynamic subjectFilter = "all";
  String sortOption = "title-asc";

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      setState(() {
        loading = true;
      });
      
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      final data = _generateDemoData();
      setState(() {
        materials = data;
        filteredMaterials = data;
      });
    } catch (err) {
      setState(() {
        error = "Failed to load materials";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  List<Material> _generateDemoData() {
    return [
      Material(
        id: 1,
        title: "Algebra Basics",
        subject: 1,
        isDemo: true,
        uploadedDate: DateTime.now().subtract(const Duration(days: 2)),
        fileSize: "2.4 MB",
        file: "algebra.pdf",
      ),
      Material(
        id: 2,
        title: "Chemical Reactions",
        subject: 3,
        isDemo: false,
        uploadedDate: DateTime.now().subtract(const Duration(days: 5)),
        fileSize: "3.1 MB",
        file: "chemistry.pdf",
      ),
      Material(
        id: 3,
        title: "World War II Timeline",
        subject: 5,
        isDemo: true,
        uploadedDate: DateTime.now().subtract(const Duration(days: 1)),
        fileSize: "1.8 MB",
        file: "history.pdf",
      ),
      Material(
        id: 4,
        title: "Cell Biology Fundamentals",
        subject: 4,
        isDemo: true,
        uploadedDate: DateTime.now().subtract(const Duration(days: 3)),
        fileSize: "2.7 MB",
        file: "biology.pdf",
      ),
      Material(
        id: 5,
        title: "Trigonometry Formulas",
        subject: 1,
        isDemo: false,
        uploadedDate: DateTime.now().subtract(const Duration(days: 7)),
        fileSize: "1.5 MB",
        file: "trigonometry.pdf",
      ),
      Material(
        id: 6,
        title: "Grammar Rules",
        subject: 8,
        isDemo: true,
        uploadedDate: DateTime.now().subtract(const Duration(days: 4)),
        fileSize: "2.0 MB",
        file: "english.pdf",
      ),
    ];
  }

  void _applyFilters() {
    List<Material> result = [...materials];
    
    // Apply search filter
    if (searchQuery.isNotEmpty) {
      result = result.where((material) =>
          material.title.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    
    // Apply subject filter
    if (subjectFilter != "all") {
      result = result.where((material) => material.subject == subjectFilter)
          .toList();
    }
    
    // Apply sorting
    result.sort((a, b) {
      switch (sortOption) {
        case "title-asc":
          return a.title.compareTo(b.title);
        case "title-desc":
          return b.title.compareTo(a.title);
        case "date-asc":
          return a.uploadedDate.compareTo(b.uploadedDate);
        case "date-desc":
          return b.uploadedDate.compareTo(a.uploadedDate);
        default:
          return 0;
      }
    });
    
    setState(() {
      filteredMaterials = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isDesktop = mediaWidth >= 1100;
    final isTablet = mediaWidth >= 600;
    
    if (loading) {
      return _buildLoadingSkeleton(mediaWidth);
    }
    
    if (error != null) {
      return _buildErrorWidget();
    }
    
    return Scaffold(
      drawer: !isDesktop ? const AppDrawer(activeIndex: 3) : null,
      body: Row(
        children: [
          if (isDesktop) const AppDrawer(activeIndex: 3),
          if (isTablet && !isDesktop)
                const IvyNavRail(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                IvyAppBar(
                  title: 'Study Materials',
                  showMenuButton: !isDesktop,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Study Materials',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Access demo study materials for your preparation',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        
                        // Search and Filter Controls
                        _buildSearchAndFilterControls(mediaWidth),
                        const SizedBox(height: 16),
                        
                        // Demo Version Notice
                        _buildDemoNoticeCard(),
                        const SizedBox(height: 24),
                        
                        // Materials Grid
                        if (filteredMaterials.isNotEmpty)
                          _buildMaterialsGrid(mediaWidth)
                        else
                          _buildEmptyState(),
                        
                        const SizedBox(height: 24),
                        
                        // Premium and App Download Cards
                        _buildPromoCards(mediaWidth),
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

  Widget _buildSearchAndFilterControls(double mediaWidth) {
    final isSmallScreen = mediaWidth < 640;
    
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search materials...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
              _applyFilters();
            });
          },
        ),
        const SizedBox(height: 12),
        StaggeredGrid.count(
          crossAxisCount: mediaSetup(mediaWidth, sm: 1, md: 2).toInt(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            DropdownButtonFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  )
                ),
                value: subjectFilter == "all" ? "all" : subjectFilter.toString(),
                items: [
                  const DropdownMenuItem(
                    value: "all",
                    child: Text("All Subjects"),
                  ),
                  ...availableSubjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject.id.toString(),
                      child: Text(subject.name),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    subjectFilter = value == "all" ? "all" : int.parse(value!);
                    _applyFilters();
                  });
                },
              ),

              DropdownButtonFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  )
                ),
                value: sortOption,
                items: const [
                  DropdownMenuItem(
                    value: "title-asc",
                    child: Text("Title (A-Z)"),
                  ),
                  DropdownMenuItem(
                    value: "title-desc",
                    child: Text("Title (Z-A)"),
                  ),
                  DropdownMenuItem(
                    value: "date-asc",
                    child: Text("Date (Oldest)"),
                  ),
                  DropdownMenuItem(
                    value: "date-desc",
                    child: Text("Date (Newest)"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    sortOption = value!;
                    _applyFilters();
                  });
                },
              ),

          ]
        ),
        // Row(
        //   children: [
        //     Expanded(
        //       child: 
        //     ),
        //     const SizedBox(width: 12),
        //     Expanded(
        //       child: 
        //     ),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildDemoNoticeCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Demo Version',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[700]),
                      children: const [
                        TextSpan(
                          text: "You're using the demo version with limited materials. "),
                        TextSpan(
                          text: "Subscribe to Premium",
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: " or "),
                        TextSpan(
                          text: "download our app",
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: " for full access."),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsGrid(double mediaWidth) {
    final crossAxisCount = mediaSetup(mediaWidth, sm: 1, md: 2, lg: 3).toInt();

    return StaggeredGrid.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: filteredMaterials.map((material) {
        final subjectInfo = SUBJECTS[material.subject] ?? 
            SubjectInfo(name: 'Subject ${material.subject}', icon: Icons.article);
        return StaggeredGridTile.fit(
          crossAxisCellCount: 1, 
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(subjectInfo.icon, color: Colors.blue),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              subjectInfo.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: (){}, 
                          icon: const Icon(Icons.download)
                        )

                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      material.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uploaded on ${DateFormat('MMM d, y').format(material.uploadedDate)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 5,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(material.fileSize),
                          backgroundColor: Colors.grey[200],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to material detail
                          },
                          child: const Text('View Material'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
      
    );
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: filteredMaterials.length,
      itemBuilder: (context, index) {
        final material = filteredMaterials[index];
        final subjectInfo = SUBJECTS[material.subject] ?? 
            SubjectInfo(name: 'Subject ${material.subject}', icon: Icons.article);
        
        return ;
      },
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'No materials found matching your criteria',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildPromoCards(double mediaWidth) {
    final isSingleColumn = mediaWidth < 640;
    
    return Column(
      children: [
        if (isSingleColumn) ...[
          _buildPromoCard(
            icon: Icons.lock,
            title: "Premium Materials",
            description: "Get access to our complete library of study materials",
            buttonText: "Upgrade to Premium",
          ),
          const SizedBox(height: 16),
          _buildPromoCard(
            icon: Icons.download,
            title: "Mobile App",
            description: "Download our app for offline access to materials",
            buttonText: "Download App",
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildPromoCard(
                  icon: Icons.lock,
                  title: "Premium Materials",
                  description: "Get access to our complete library of study materials",
                  buttonText: "Upgrade to Premium",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPromoCard(
                  icon: Icons.download,
                  title: "Mobile App",
                  description: "Download our app for offline access to materials",
                  buttonText: "Download App",
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPromoCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
  }) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      // Handle button press
                    },
                    child: Text(buttonText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(double mediaWidth) {
    final crossAxisCount = mediaSetup(mediaWidth, sm: 1, md: 2, lg: 2).toInt();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Materials'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Skeleton(height: 32, width: 200),
            const SizedBox(height: 8),
            const Skeleton(height: 16, width: 250),
            const SizedBox(height: 24),
            
            const Skeleton(height: 56),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: Skeleton(height: 56)),
                SizedBox(width: 12),
                Expanded(child: Skeleton(height: 56)),
              ],
            ),
            const SizedBox(height: 24),
            
            const Skeleton(height: 80),
            const SizedBox(height: 24),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Skeleton(height: 40, width: 40),
                                SizedBox(width: 8),
                                Skeleton(height: 20, width: 80),
                              ],
                            ),
                            Skeleton(height: 24, width: 60),
                          ],
                        ),
                        SizedBox(height: 12),
                        Skeleton(height: 20, width: 150),
                        SizedBox(height: 4),
                        Skeleton(height: 16),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Skeleton(height: 16, width: 80),
                            Skeleton(height: 36, width: 100),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Skeleton(height: 120)),
                SizedBox(width: mediaWidth < 640 ? 0 : 16),
                if (mediaWidth >= 640) 
                  const Expanded(child: Skeleton(height: 120)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Materials'),
      ),
      body: Center(
        child: Card(
          color: Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Error loading materials',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      error!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Material {
  final int id;
  final String title;
  final int subject;
  final bool isDemo;
  final DateTime uploadedDate;
  final String fileSize;
  final String file;

  Material({
    required this.id,
    required this.title,
    required this.subject,
    required this.isDemo,
    required this.uploadedDate,
    required this.fileSize,
    required this.file,
  });
}

class SubjectInfo {
  final String name;
  final IconData icon;

  SubjectInfo({required this.name, required this.icon});
}

final Map<int, SubjectInfo> SUBJECTS = {
  1: SubjectInfo(name: "Mathematics", icon: Icons.calculate),
  2: SubjectInfo(name: "Physics", icon: Icons.science),
  3: SubjectInfo(name: "Chemistry", icon: Icons.science),
  4: SubjectInfo(name: "Biology", icon: Icons.science),
  5: SubjectInfo(name: "History", icon: Icons.book),
  6: SubjectInfo(name: "Geography", icon: Icons.book),
  7: SubjectInfo(name: "Civics", icon: Icons.book),
  8: SubjectInfo(name: "English", icon: Icons.book),
};

final availableSubjects = SUBJECTS.entries.map((entry) {
  return AvailableSubject(id: entry.key, name: entry.value.name);
}).toList();

class AvailableSubject {
  final int id;
  final String name;

  AvailableSubject({required this.id, required this.name});
}

class Skeleton extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const Skeleton({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}