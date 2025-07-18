import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ivy_path/models/subject_model.dart';
import 'package:ivy_path/screens/materials/pdf_viewer_screen.dart';
import 'package:ivy_path/widgets/layout_widget.dart';
import 'package:ivy_path/services/material_service.dart';
import '/models/material_model.dart' as mm;

double mediaSetup(double size, {double? sm, double? md, double? lg}) {
  if (size < 640) {
    return sm ?? md ?? lg ?? 1;
  } else if (size < 1024) {
    return md ?? lg ?? sm ?? 1;
  } else {
    return lg ?? md ?? sm ?? 1;
  }
}

IconData getIcon(String name) {
  switch (name.toLowerCase()) {
    case 'mathematics':
      return Icons.calculate;
    case 'physics' || "chemistry" || "biology":
      return Icons.science;
    default:
      return Icons.article;
  }
}

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  final MaterialService _materialService = MaterialService();
  List<mm.Material> materials = [];
  List<mm.Material> filteredMaterials = [];
  List<AvailableSubject> availableSubjects = [];
  Map<int, SubjectInfo> SUBJECTS = {};
  bool loading = true;
  String? error;

  // Filter and sort states
  String searchQuery = "";
  dynamic subjectFilter = "all";
  String sortOption = "title-asc";

  @override
  void initState() {
    super.initState();
    _updateAvailableSubjects();
    _loadMaterials();
  }

  void _updateAvailableSubjects() {
    final subjectsBox = Hive.box<Subject>('subjects');
    SUBJECTS = {
      for (var subject in subjectsBox.values)
        subject.id: SubjectInfo(name: subject.name, icon: getIcon(subject.name)),
    };
    
    setState(() {
      availableSubjects = subjectsBox.values
          .map((subject) => AvailableSubject(id: subject.id, name: subject.name))
          .toList();
    });
  }

  Future<void> _loadMaterials() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final data = await _materialService.getMaterials();
      setState(() {
        materials = data;
        filteredMaterials = data;
        loading = false;
      });
    } catch (err) {
      setState(() {
        error = err.toString();
        loading = false;
      });
    }
  }

  Future<void> _downloadMaterial(mm.Material material) async {
    try {
      final filePath = await _materialService.downloadMaterial(material);
      // Handle successful download (e.g., open file)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material downloaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download material: ${e.toString()}')),
      );
    }
  }

  void _applyFilters() {
    List<mm.Material> result = [...materials];
    
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return _buildErrorWidget();

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
                          'Access premium study materials for your preparation',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        
                        // Search and Filter Controls
                        _buildSearchAndFilterControls(mediaWidth),
                        const SizedBox(height: 16),
                        
                        // Demo Version Notice
                        // _buildDemoNoticeCard(),
                        const SizedBox(height: 24),
                        
                        // Materials Grid
                        if (filteredMaterials.isNotEmpty)
                          _buildMaterialsGrid(mediaWidth)
                        else
                          _buildEmptyState(),
                        
                        const SizedBox(height: 24),
                        
                        // Premium and App Download Cards
                        // _buildPromoCards(mediaWidth),
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
                  }),
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
            final isDownloaded = _materialService.isDownloaded(material.id);
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
                        FutureBuilder(
                          future: isDownloaded, 
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return IconButton(
                                onPressed: () => {}, 
                                icon: const Icon(Icons.download)
                              );
                            }
                            return IconButton(
                              onPressed: () async {
                               snapshot.data! ? {} : 
                               await _downloadMaterial(material);
                                setState(() {});
                              },
                              icon: snapshot.data! ? const Icon(Icons.download_done) : const Icon(Icons.download)
                            );
                          }
                        ),

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
                          onPressed: () async {
                            final isDownloaded = await _materialService.isDownloaded(material.id);
                            if (!isDownloaded) {
                              // If not downloaded, view from URL
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PDFViewerScreen(
                                    source: material.file,
                                    title: material.title,
                                    isUrl: true,
                                  ),
                                ),
                              );
                            } else {
                              // If downloaded, view from local file
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
                              
                            }
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

class SubjectInfo {
  final String name;
  final IconData icon;

  SubjectInfo({required this.name, required this.icon});
}

// final availableSubjects = SUBJECTS.entries.map((entry) {
//   return AvailableSubject(id: entry.key, name: entry.value.name);
// }).toList();

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