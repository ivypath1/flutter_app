import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ivy_path/screens/session_screen.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';
import 'package:ivy_path/widgets/layout_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  String? _mode;
  final List<String> _selectedSubjects = [];
  final Map<String, Map<String, dynamic>> _subjectSettings = {};
  String _duration = "60";
  bool _shuffleQuestions = false;
  bool _shuffleOptions = false;
  String _selectedType = "all";
  final List<String> _selectedMockSubjects = [];

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

  final List<Map<String, dynamic>> _subjects = [
    {
      "id": "mathematics",
      "name": "Mathematics",
      "sections": ["Algebra", "Calculus", "Statistics"],
      "maxQuestions": 5,
    },
    {
      "id": "english",
      "name": "English Language",
      "sections": ["Grammar", "Comprehension", "Vocabulary"],
      "maxQuestions": 5,
    },
    {
      "id": "physics",
      "name": "Physics",
      "sections": ["Mechanics", "Waves", "Electricity"],
      "maxQuestions": 5,
    },
    {
      "id": "chemistry",
      "name": "Chemistry",
      "sections": ["Physical", "Organic", "Inorganic"],
      "maxQuestions": 5,
    },
  ];

  final List<Map<String, dynamic>> _mockSubjects = [
    {"id": "mathematics", "name": "Mathematics", "questions": 40},
    {"id": "english", "name": "English Language", "questions": 50},
    {"id": "physics", "name": "Physics", "questions": 40},
    {"id": "chemistry", "name": "Chemistry", "questions": 40},
  ];

  final List<Map<String, dynamic>> _selectTypes = [
    {"value": "all", "label": "All"},
    {"value": "section1", "label": "Section 1"},
    {"value": "section2", "label": "Section 2"},
    {"value": "section3", "label": "Section 3"},
  ];

  void _handleSubjectToggle(String subjectId) {
    setState(() {
      if (_selectedSubjects.contains(subjectId)) {
        _selectedSubjects.remove(subjectId);
        _subjectSettings.remove(subjectId);
      } else {
        if (_selectedSubjects.length < 4) {
          _selectedSubjects.add(subjectId);
          _subjectSettings[subjectId] = {"questions": 5, "section": "all"};
        }
      }
    });
  }

  void _handleMockSubjectToggle(String subjectId) {
    setState(() {
      if (_selectedMockSubjects.contains(subjectId)) {
        _selectedMockSubjects.remove(subjectId);
      } else {
        _selectedMockSubjects.add(subjectId);
      }
    });
  }

  void _updateSubjectSettings(String subjectId, String field, dynamic value) {
    setState(() {
      _subjectSettings[subjectId]?[field] = value;
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
            "questions": _subjectSettings[subjectId]?["questions"] ?? 5,
            "section": _subjectSettings[subjectId]?["section"] ?? "all",
          };
        }).toList(),
        "duration": double.tryParse(_duration) ?? 60, // Default to 60 if parsing fails
        "shuffleQuestions": _shuffleQuestions,
        "shuffleOptions": _shuffleOptions,
      };
    }
    // For mock mode
    else {
      return {
        "mode": "mock",
        "subjects": _selectedMockSubjects.map((subjectId) {
          final subject = _mockSubjects.firstWhere((s) => s["id"] == subjectId);
          return {
            "id": subjectId,
            "questions": subject["questions"],
            "section": "all", // Mock exams typically use all sections
          };
        }).toList(),
        "duration": 45, // Mock exams typically have fixed duration
        "shuffleQuestions": _shuffleQuestions,
        "shuffleOptions": _shuffleOptions,
      };
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
      drawer: !isDesktop ? const AppDrawer() : null,
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      //   title: const Text('Practice Setup'),
      // ),
      body: Row(
        children: [
          if (isDesktop) const AppDrawer(),
          if (isTablet && !isDesktop)
            const IvyNavRail(),
          
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
                                        "Demo Version",
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
                                          children: [
                                            const TextSpan(text: "You're using the demo version with limited features. "),
                                            TextSpan(
                                              text: "Subscribe to Premium",
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            const TextSpan(text: " or "),
                                            TextSpan(
                                              text: "download our app",
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            const TextSpan(text: " for full access."),
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
                                      "Select Practice Mode",
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
                                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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
                                                  onChanged: null, // Disabled for demo
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "Shuffle Questions",
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                                const SizedBox(width: 8),
                                                const Chip(
                                                  label: Text("Premium"),
                                                  side: BorderSide.none,
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: _shuffleOptions,
                                                  onChanged: null, // Disabled for demo
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "Shuffle Options",
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                                const SizedBox(width: 8),
                                                const Chip(
                                                  label: Text("Premium"),
                                                  side: BorderSide.none,
                                                  visualDensity: VisualDensity.compact,
                                                ),
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
                                                          const Chip(
                                                            label: Text("Demo"),
                                                            side: BorderSide.none,
                                                            visualDensity: VisualDensity.compact,
                                                          ),
                                                        ],
                                                      ),
                                                      
                                                      if (isSelected) ...[
                                                        const SizedBox(height: 12),
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              "Questions (Max 5)",
                                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            TextFormField(
                                                              initialValue: _subjectSettings[subject["id"]]?["questions"]?.toString() ?? "5",
                                                              onChanged: (value) {
                                                                final num = int.tryParse(value) ?? 5;
                                                                _updateSubjectSettings(
                                                                  subject["id"],
                                                                  "questions",
                                                                  num.clamp(1, 5),
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
                                                            DropdownButtonFormField<String>(
                                                              value: _subjectSettings[subject["id"]]?["section"] ?? "all",
                                                              items: [
                                                                DropdownMenuItem(
                                                                  value: "all",
                                                                  child: Text("All"),
                                                                ),
                                                                ...(subject["sections"] as List<String>).map((section) {
                                                                  return DropdownMenuItem(
                                                                    value: section,
                                                                    child: Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: [
                                                                        Text("Section ${subject["sections"].indexOf(section) + 1}"),
                                                                        const Chip(
                                                                          label: Text("Premium"),
                                                                          side: BorderSide.none,
                                                                          visualDensity: VisualDensity.compact,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                }).toList(),
                                                              ],
                                                              onChanged: (value) {
                                                                if (value == "all") {
                                                                  _updateSubjectSettings(
                                                                    subject["id"],
                                                                    "section",
                                                                    value,
                                                                  );
                                                                }
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
                                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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
                                                "${_selectedSubjects.fold<int>(0, (total, subjectId) => total + ((_subjectSettings[subjectId]?["questions"] ?? 0) as int))} questions",
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
                                                if (type["value"] != "all")
                                                  const Chip(
                                                    label: Text("Premium"),
                                                    side: BorderSide.none,
                                                    visualDensity: VisualDensity.compact,
                                                  ),
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
                                            "${_selectedMockSubjects.length}/4 selected",
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
                                          final isSelected = _selectedMockSubjects.contains(subject["id"]);
                                          // final isDisabled = _selectedSubjects.length >= 4 && !isSelected;
                                          
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
                                              child: InkWell(
                                                onTap: () => _handleSubjectToggle(subject["id"]),
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
                                                          Chip(
                                                            label: Text("${subject["questions"]} Questions"),
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
                                          Checkbox(
                                            value: _shuffleQuestions,
                                            onChanged: null, // Disabled for demo
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Shuffle Questions",
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          const SizedBox(width: 8),
                                          const Chip(
                                            label: Text("Premium"),
                                            side: BorderSide.none,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _shuffleOptions,
                                            onChanged: null, // Disabled for demo
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Shuffle Options",
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          const SizedBox(width: 8),
                                          const Chip(
                                            label: Text("Premium"),
                                            side: BorderSide.none,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  Card(
                                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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
                                                "170 questions",
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
                                        ? _selectedMockSubjects.isEmpty
                                        : _selectedSubjects.isEmpty) || _mode == null
                                        ? null
                                        : () {
                                            final config = _getSessionConfiguration();
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
      ),
    );
  }
}