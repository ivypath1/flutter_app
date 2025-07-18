import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ivy_path/models/subject_model.dart';
import 'package:ivy_path/providers/practice_subject.dart';
import 'package:ivy_path/screens/session_screen.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';
import 'package:ivy_path/widgets/layout_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  late final PracticeConfigProvider _provider;
  String? _mode;
  final List<int> _selectedSubjects = [];
  final List<Map<String, dynamic>> _subjectSettings = [];
  String _duration = "60";
  bool _shuffleQuestions = false;
  bool _shuffleOptions = false;
  String _selectedType = "all";

  final List<Map<String, dynamic>> _practiceModes = [
    {
      "value": "study",
      "label": "Study Mode",
      "icon": Icons.lightbulb_outline,
      "description": "Answers and explanations are shown instantly",
    },
    {
      "value": "practice",
      "label": "Practice Mode",
      "icon": Icons.edit,
      "description": "Answers are shown after the session ends",
    },
    {
      "value": "mock",
      "label": "Mock UTME",
      "icon": Icons.science,
      "description": "Simulates real exam with default program subjects and a timer",
    },
  ];


  List<Map<String, dynamic>> get _subjects {
    return _provider.subjects.map((subject) {
      return {
        "id": subject.id,
        "name": subject.name,
        "sections": subject.sections,
        "maxQuestions": 5,
        "section": subject.sections
      };
    }).toList();
  }

  // Convert provider subjects to mock format
  List<Map<String, dynamic>> get _mockSubjects {
    return _provider.subjects.map((subject) {
      return {
        "id": subject.id,
        "name": subject.name,
        "questions": 10, // Default mock exam question count
        "section": subject.sections
      };
    }).toList();
  }

  final List<Map<String, dynamic>> _selectTypes = [
    {"value": "all", "label": "All"},
  ];

  void _handleSubjectToggle(int subjectId) {
    setState(() {
      if (_selectedSubjects.contains(subjectId)) {
        _selectedSubjects.remove(subjectId);

        _subjectSettings.removeWhere((item) => item['id'] == subjectId);
      } else {
        if (_selectedSubjects.length < 4) {
          _selectedSubjects.add(subjectId);
          _subjectSettings.add({"id": subjectId, "section": 0, "questions": 10});
        }
      }
    });
  }

  void _updateSubjectSettings(int subjectId, String field, dynamic value) {
    int index = _subjectSettings.indexWhere((item) => item['id'] == subjectId);
    setState(() {
      _subjectSettings[index][field] = value;
    });
  }

  Map<String, dynamic> _getSessionConfiguration() {
    // For practice/study mode
    if (_mode != "mock") {
      return {
        "mode": _mode ?? "practice", // Default to practice if not set
        "subjects": _selectedSubjects.map((subjectId) {
          return {
            "id": subjectId,
            "questions": _subjectSettings[_subjectSettings.indexWhere((item) => item['id'] == subjectId)]["questions"] ?? 5,
            "section": _subjectSettings[_subjectSettings.indexWhere((item) => item['id'] == subjectId)]["section"] ?? "all",
          };
        }).toList(),
        "duration": double.tryParse(_duration) ?? 60, // Default to 60 if parsing fails
        "shuffleQuestions": _shuffleQuestions,
        "shuffleOptions": _shuffleOptions,
      };
    }
    // For mock mode
    else {
      // print(_subjects);
      return {
        "mode": "mock",
        "subjects": _subjects.map((subject) {
          return {
            "id": subject["id"],
            "questions": 10,
            "section": 0, // Mock exams typically use all sections
          };
        }).toList(),
        "duration": 45.0, // Mock exams typically have fixed duration
        "shuffleQuestions": true,
        "shuffleOptions": true,
      };
    }
  }

   @override
  void initState() {
    super.initState();
    _provider = context.read<PracticeConfigProvider>();
    // Load subjects if not already loaded
    if (_provider.loadingStatus == LoadingStatus.initial) {
      _provider.loadSubjects();
    }
  }


  @override
  Widget build(BuildContext context) {
    final selectedMode = _practiceModes.firstWhere(
      (m) => m["value"] == _mode,
      orElse: () => {},
    );
    final size = MediaQuery.of(context).size.width;
    final isDesktop = size >= 1100;
    final isTablet = size >= 600;

    return Scaffold(
      drawer: !isDesktop ? const AppDrawer(activeIndex: 2,) : null,
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      //   title: const Text('Practice Setup'),
      // ),
      body: Consumer<PracticeConfigProvider>(
        builder: (context, provider, child) {
          // Show loading state
          if (provider.loadingStatus == LoadingStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
           // Show error state
          if (provider.loadingStatus == LoadingStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage),
                  ElevatedButton(
                    onPressed: provider.loadSubjects,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              if (isDesktop) const AppDrawer(activeIndex: 2),
              if (isTablet && !isDesktop) const IvyNavRail(),

              Expanded(
                child: CustomScrollView(
                  slivers: [
                    IvyAppBar(
                      title: 'Practice Setup',
                      showMenuButton: !isDesktop,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: mediaSetup(size, md: 16, lg: 100), vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Premium Version",
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: TextSpan(
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                              ),
                                              children: const [
                                                TextSpan(text: "You're using the premium version. "),
                                                TextSpan(text: "Practice unlimited questions with full access to explanations, timed modes, and performance tracking."),
                                              ],
                                            ),
                                          ),

                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn().slideY(
                              begin: 0.2,
                              duration: 500.ms,
                              delay: 100.ms,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Text(
                              "Practice Setup",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Configure your practice session",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Select Mode",
                                          style: Theme.of(context).textTheme.labelLarge,
                                        ),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<String>(
                                          value: _mode,
                                          items: _practiceModes.map((mode) {
                                            return DropdownMenuItem<String>(
                                              value: mode["value"],
                                              child: Row(
                                                children: [
                                                  Icon(mode["icon"], size: 20),
                                                  const SizedBox(width: 8),
                                                  Text(mode["label"]),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _mode = value;
                                            });
                                          },
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    if (selectedMode.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Card(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  selectedMode["description"],
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    
                                    if (_mode != null && _mode != "mock") ...[
                                      const SizedBox(height: 24),
                                      if (_mode == "practice") ...[
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  "Duration (minutes)",
                                                  style: Theme.of(context).textTheme.labelLarge,
                                                ),
                                                const SizedBox(width: 16),
                                                SizedBox(
                                                  width: 100,
                                                  child: TextFormField(
                                                    initialValue: _duration,
                                                    onChanged: (value) => setState(() => _duration = value),
                                                    keyboardType: TextInputType.number,
                                                    decoration: const InputDecoration(
                                                      isDense: true,
                                                      border: OutlineInputBorder(),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Checkbox(
                                                      value: _shuffleQuestions,
                                                      // onChanged: null, // Disabled for demo
                                                      onChanged: (value){
                                                        setState(() {
                                                          _shuffleQuestions = value!;
                                                        });
                                                      }, // Disabled for demo
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Shuffle Questions",
                                                      style: Theme.of(context).textTheme.bodyMedium,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // const Chip(
                                                    //   label: Text("Premium"),
                                                    //   side: BorderSide.none,
                                                    //   visualDensity: VisualDensity.compact,
                                                    // ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Checkbox(
                                                      value: _shuffleOptions,
                                                      // onChanged: null, // Disabled for demo
                                                      onChanged: (value){
                                                        setState(() {
                                                          _shuffleOptions = value!;
                                                        });
                                                      }, // Disabled for demo
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Shuffle Options",
                                                      style: Theme.of(context).textTheme.bodyMedium,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // const Chip(
                                                    //   label: Text("Premium"),
                                                    //   side: BorderSide.none,
                                                    //   visualDensity: VisualDensity.compact,
                                                    // ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                      
                                      const SizedBox(height: 24),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Select Subjects (Max 4)",
                                                style: Theme.of(context).textTheme.labelLarge,
                                              ),
                                              Text(
                                                "${_selectedSubjects.length}/4 selected",
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          StaggeredGrid.count(
                                            crossAxisCount: mediaSetup(size, sm: 1, md: 2).toInt(),
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            children: _subjects.map((subject) {
                                              final isSelected = _selectedSubjects.contains(subject["id"]);
                                              final isDisabled = _selectedSubjects.length >= 4 && !isSelected;
                                              
                                              return StaggeredGridTile.fit(
                                                crossAxisCellCount: 1,
                                                child: Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    side: BorderSide(
                                                      color: isSelected
                                                          ? Theme.of(context).colorScheme.primary
                                                          : Theme.of(context).dividerColor,
                                                    ),
                                                  ),
                                                  color: isDisabled
                                                      ? Theme.of(context).disabledColor.withOpacity(0.05)
                                                      : null,
                                                  child: InkWell(
                                                    onTap: isDisabled ? null : () => _handleSubjectToggle(subject["id"]),
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric
                                                      (horizontal: 12, vertical: 15),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    width: 20,
                                                                    height: 20,
                                                                    decoration: BoxDecoration(
                                                                      shape: BoxShape.circle,
                                                                      border: Border.all(
                                                                        color: isSelected
                                                                            ? Theme.of(context).colorScheme.primary
                                                                            : Theme.of(context).dividerColor,
                                                                      ),
                                                                      color: isSelected
                                                                          ? Theme.of(context).colorScheme.primary
                                                                          : Colors.transparent,
                                                                    ),
                                                                    child: isSelected
                                                                        ? Icon(
                                                                            Icons.check,
                                                                            size: 14,
                                                                            color: Theme.of(context).colorScheme.onPrimary,
                                                                          )
                                                                        : null,
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  Text(
                                                                    subject["name"],
                                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              // const Chip(
                                                              //   label: Text("Demo"),
                                                              //   side: BorderSide.none,
                                                              //   visualDensity: VisualDensity.compact,
                                                              // ),
                                                            ],
                                                          ),
                                                          
                                                          if (isSelected) ...[
                                                            const SizedBox(height: 12),
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  "Questions (Max 50)",
                                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                TextFormField(
                                                                  initialValue: _subjectSettings[_subjectSettings.indexWhere((item) => item['id'] == subject["id"])]["questions"]?.toString() ?? "10",
                                                                  onChanged: (value) {
                                                                    final num = int.tryParse(value) ?? 10;
                                                                    _updateSubjectSettings(
                                                                      subject["id"],
                                                                      "questions",
                                                                      num.clamp(1, 50),
                                                                    );
                                                                  },
                                                                  keyboardType: TextInputType.number,
                                                                  decoration: const InputDecoration(
                                                                    isDense: true,
                                                                    border: OutlineInputBorder(),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            
                                                            const SizedBox(height: 12),
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  "Type",
                                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                DropdownButtonFormField<int>(
                                                                  value: _subjectSettings[_subjectSettings.indexWhere((item) => item['id'] == subject["id"])]["section"] ?? 0,
                                                                  items: [
                                                                    const DropdownMenuItem(
                                                                      value: 0,
                                                                      child: Text("All"),
                                                                    ),
                                                                    ...(subject["sections"] as List<Section>).map((Section section) {
                                                                      return DropdownMenuItem(
                                                                        value: section.id,
                                                                        child: Row(
                                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            Text(section.name),
                                                                            // const Chip(
                                                                            //   label: Text("Premium"),
                                                                            //   side: BorderSide.none,
                                                                            //   visualDensity: VisualDensity.compact,
                                                                            // ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    }),
                                                                  ],
                                                                  onChanged: (value) {
                                                                    _updateSubjectSettings(
                                                                      subject["id"],
                                                                      "section",
                                                                      value,
                                                                    );
                                                                    
                                                                  },
                                                                  decoration: const InputDecoration(
                                                                    isDense: true,
                                                                    border: OutlineInputBorder(),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      Card(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Total Questions",
                                                    style: Theme.of(context).textTheme.labelLarge,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "${_selectedSubjects.fold<int>(0, (total, subjectId) {
                                                      int index = _subjectSettings.indexWhere((item) => item['id'] == subjectId);
                                                      return total + ((_subjectSettings[index]["questions"] ?? 0) as int);
                                                    })} questions",
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "Duration",
                                                    style: Theme.of(context).textTheme.labelLarge,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _mode == "practice" ? "$_duration minutes" : "Unlimited",
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    
                                    if (_mode == "mock") ...[
                                      const SizedBox(height: 24),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Select Type",
                                            style: Theme.of(context).textTheme.labelLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<String>(
                                            value: _selectedType,
                                            items: _selectTypes.map((type) {
                                              return DropdownMenuItem<String>(
                                                value: type["value"],
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(type["label"]),
                                                    // if (type["value"] != "all")
                                                    //   const Chip(
                                                    //     label: Text("Premium"),
                                                    //     side: BorderSide.none,
                                                    //     visualDensity: VisualDensity.compact,
                                                    //   ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              if (value == "all") {
                                                setState(() {
                                                  _selectedType = value ?? "all";
                                                });
                                              }
                                            },
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 24),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Program Subjects",
                                                style: Theme.of(context).textTheme.labelLarge,
                                              ),
                                              Text(
                                                "${_subjects.length}/4 selected",
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          StaggeredGrid.count(
                                            crossAxisCount: mediaSetup(size, sm: 1, md: 2).toInt(),
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            children: _mockSubjects.map((subject) {
                                              // final isDisabled = _selectedSubjects.length >= 4 && !isSelected;
                                              
                                              return StaggeredGridTile.fit(
                                                crossAxisCellCount: 1,
                                                child: Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    side: BorderSide(
                                                      color: Theme.of(context).colorScheme.primary
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {},
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(12),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    width: 20,
                                                                    height: 20,
                                                                    decoration: BoxDecoration(
                                                                      shape: BoxShape.circle,
                                                                      border: Border.all(
                                                                        color: Theme.of(context).colorScheme.primary
                                                                      ),
                                                                      color: Theme.of(context).colorScheme.primary
                                                                    ),
                                                                    child: Icon(
                                                                            Icons.check,
                                                                            size: 14,
                                                                            color: Theme.of(context).colorScheme.onPrimary,
                                                                          ),
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  Text(
                                                                    subject["name"],
                                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Chip(
                                                                label: Text("${subject["questions"]} "),
                                                                side: BorderSide.none,
                                                                visualDensity: VisualDensity.compact,
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
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Checkbox(
                                                value: true,
                                                onChanged: null,
                                                // onChanged: (value){
                                                //   setState(() {
                                                //     _shuffleQuestions = value!;
                                                //   });
                                                // }, // Disabled for demo
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Shuffle Questions",
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              const SizedBox(width: 8),
                                              
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Checkbox(
                                                value: true,
                                                onChanged: null, // Disabled for demo
                                                // onChanged: (value){
                                                //   setState(() {
                                                //     _shuffleOptions = value!;
                                                //   });
                                                // },
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Shuffle Options",
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              const SizedBox(width: 8),
                                              
                                            ],
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      Card(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Total Questions",
                                                    style: Theme.of(context).textTheme.labelLarge,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "40 questions",
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "Duration",
                                                    style: Theme.of(context).textTheme.labelLarge,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "45 minutes",
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: (_mode == "mock"
                                            ? _subjects.isEmpty
                                            : _selectedSubjects.isEmpty) || _mode == null
                                            ? null
                                            : () {
                                                final config = _getSessionConfiguration();
                                                // print(config);
                                                Navigator.push(
                                                  context, 
                                                  MaterialPageRoute(
                                                    builder: (context) => SessionPage(
                                                      mode: config["mode"],
                                                      duration: config["duration"],
                                                      shuffleOptions: config["shuffleOptions"],
                                                      shuffleQuestions: config["shuffleQuestions"],
                                                      subjects: List<Map<String, dynamic>>.from(config["subjects"]),
                                                    ),
                                                  ),
                                                );
                                              },
                                        child: const Text("Start Session"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // const SizedBox(height: 24),
                            
                            // Card(
                            //   color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            //   shape: RoundedRectangleBorder(
                            //     side: BorderSide(
                            //       color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            //     ),
                            //     borderRadius: BorderRadius.circular(12),
                            //   ),
                            //   child: Padding(
                            //     padding: const EdgeInsets.all(16),
                            //     child: Row(
                            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //       children: [
                            //         Column(
                            //           crossAxisAlignment: CrossAxisAlignment.start,
                            //           children: [
                            //             Text(
                            //               "Get Full Access",
                            //               style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            //                 fontWeight: FontWeight.bold,
                            //               ),
                            //             ),
                            //             const SizedBox(height: 4),
                            //             Text(
                            //               "Unlock unlimited questions, detailed explanations, and more",
                            //               style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            //                 color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //         OutlinedButton.icon(
                            //           onPressed: () {
                            //             // Navigate to download page
                            //           },
                            //           icon: const Icon(Icons.download, size: 16),
                            //           label: const Text("Upgrade account"),
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}