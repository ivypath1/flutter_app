import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

import 'package:ivy_path/screens/result_screen.dart';

class SessionPage extends StatefulWidget {
  final String mode; // 'study', 'practice', or 'mock'
  final double duration; // in minutes
  final bool shuffleOptions;
  final bool shuffleQuestions;
  final List<Map<String, dynamic>> subjects;
  
  const SessionPage({
    super.key, 
    required this.mode,
    required this.duration,
    this.shuffleOptions = false,
    this.shuffleQuestions = false,
    required this.subjects,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> with SingleTickerProviderStateMixin {
  int _currentSubjectIndex = 0;
  int _currentQuestion = 1;
  String? _selectedAnswer;
  final Map<String, Map<int, String>> _answeredQuestions = {};
  bool _showExplanation = false;
  late TabController _tabController;
  bool _sessionSubmitted = false;
  Duration _remainingTime = Duration.zero;
  late Timer _timer;
  bool _showCorrectAnswer = false;

  // Time tracking variables
  final Map<String, Duration> _subjectTimeSpent = {};
  final Map<String, DateTime?> _subjectTimers = {};
  String? _currentActiveSubject;

  final List<Map<String, dynamic>> _mockSubjects = [
    {
      "id": "mathematics",
      "name": "Mathematics",
      "questions": [
        {
          "id": 1,
          "question": "If x² + 4x + 4 = 0, what is the value of x?",
          "options": [
            {"id": "A", "text": "-2"},
            {"id": "B", "text": "2"},
            {"id": "C", "text": "-4"},
            {"id": "D", "text": "4"},
          ],
          "correctAnswer": "A",
          "explanation": "This is a quadratic equation that can be factored as (x + 2)² = 0. Therefore, the solution is x = -2."
        },
        {
          "id": 2,
          "question": "What is the value of π (pi) to two decimal places?",
          "options": [
            {"id": "A", "text": "3.14"},
            {"id": "B", "text": "3.16"},
            {"id": "C", "text": "3.18"},
            {"id": "D", "text": "3.12"},
          ],
          "correctAnswer": "A",
          "explanation": "The value of π is approximately 3.14159, which rounds to 3.14 to two decimal places."
        },
        {
          "id": 3,
          "question": "What is the area of a triangle with base 6 and height 4?",
          "options": [
            {"id": "A", "text": "12"},
            {"id": "B", "text": "24"},
            {"id": "C", "text": "10"},
            {"id": "D", "text": "18"},
          ],
          "correctAnswer": "A",
          "explanation": "The area of a triangle is calculated as (base × height)/2, so (6 × 4)/2 = 12."
        },
      ]
    },
    {
      "id": "english",
      "name": "English",
      "questions": [
        {
          "id": 1,
          "question": "Which word is a synonym for 'happy'?",
          "options": [
            {"id": "A", "text": "Joyful"},
            {"id": "B", "text": "Sad"},
            {"id": "C", "text": "Angry"},
            {"id": "D", "text": "Tired"},
          ],
          "correctAnswer": "A",
          "explanation": "Joyful means feeling or expressing great happiness."
        },
        {
          "id": 2,
          "question": "Identify the noun in this sentence: 'The quick brown fox jumps over the lazy dog.'",
          "options": [
            {"id": "A", "text": "Fox and dog"},
            {"id": "B", "text": "Quick and brown"},
            {"id": "C", "text": "Jumps and over"},
            {"id": "D", "text": "The and lazy"},
          ],
          "correctAnswer": "A",
          "explanation": "Fox and dog are nouns as they name animals (things)."
        },
      ]
    },
    {
      "id": "physics",
      "name": "Physics",
      "questions": [
        {
          "id": 1,
          "question": "What is the SI unit of force?",
          "options": [
            {"id": "A", "text": "Newton"},
            {"id": "B", "text": "Joule"},
            {"id": "C", "text": "Watt"},
            {"id": "D", "text": "Pascal"},
          ],
          "correctAnswer": "A",
          "explanation": "Force is measured in newtons (N), named after Sir Isaac Newton."
        },
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _mockSubjects.length,
      vsync: this,
      initialIndex: _currentSubjectIndex,
    );
    _tabController.addListener(_handleTabChange);
    
    // Initialize timer if in practice or mock mode
    if (widget.mode == 'practice' || widget.mode == 'mock') {
      _remainingTime = Duration(minutes: widget.duration.toInt());
      _startTimer();
    }

    // Initialize time tracking for all subjects
  for (var subject in _mockSubjects) {
    _subjectTimeSpent[subject["id"]] = Duration.zero;
    _subjectTimers[subject["id"]] = null;
  }

  // Start timer for first subject
  _currentActiveSubject = _mockSubjects[_currentSubjectIndex]["id"];
  _subjectTimers[_currentActiveSubject!] = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (widget.mode == 'practice' || widget.mode == 'mock') {
      _timer.cancel();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime -= const Duration(seconds: 1);
        } else {
          _timer.cancel();
          if (widget.mode == 'mock') {
            _submitSession();
          }
        }
      });
    });
  }

  void _startSubjectTimer(String subjectId) {
    setState(() {
      _subjectTimers[subjectId] = DateTime.now();
      _currentActiveSubject = subjectId;
    });
  }

  void _pauseSubjectTimer(String subjectId) {
    if (_subjectTimers[subjectId] != null) {
      final now = DateTime.now();
      final elapsed = now.difference(_subjectTimers[subjectId]!);
      setState(() {
        _subjectTimeSpent[subjectId] = 
            (_subjectTimeSpent[subjectId] ?? Duration.zero) + elapsed;
        _subjectTimers[subjectId] = null;
      });
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _handleSubjectChange(_tabController.index);
    }
  }

  void _handleAnswerSelect(String value) {
    if (_sessionSubmitted && widget.mode != 'study') return;
    if (widget.mode == 'study' && _selectedAnswer != null) return;

    setState(() {
      _selectedAnswer = value;
      _answeredQuestions[_currentSubject["id"]] = {
        ...?_answeredQuestions[_currentSubject["id"]],
        _currentQuestion: value
      };

      if (widget.mode == 'study') {
        _showCorrectAnswer = true;
        _showExplanation = true;
      }
    });
  }

  void _handleNextQuestion() {
    if (_currentQuestion < _totalQuestions) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = _answeredQuestions[_currentSubject["id"]]?[_currentQuestion];
        _showExplanation = false;
        _showCorrectAnswer = false;
      });
    } else if (widget.mode == 'practice' && !_sessionSubmitted) {
      _submitSession();
    }
  }

  void _handlePreviousQuestion() {
    if (_currentQuestion > 1) {
      setState(() {
        _currentQuestion--;
        _selectedAnswer = _answeredQuestions[_currentSubject["id"]]?[_currentQuestion];
        _showExplanation = false;
        _showCorrectAnswer = _sessionSubmitted || widget.mode == 'study';
      });
    }
  }

  void _handleSubjectChange(int index) {
    final newSubjectId = _mockSubjects[index]["id"];
    
    // Pause timer for current subject
    if (_currentActiveSubject != null) {
      _pauseSubjectTimer(_currentActiveSubject!);
    }
    
    // Start timer for new subject
    _startSubjectTimer(newSubjectId);
    
    setState(() {
      _currentSubjectIndex = index;
      _currentQuestion = 1;
      _selectedAnswer = _answeredQuestions[newSubjectId]?[1];
      _showExplanation = false;
      _showCorrectAnswer = _sessionSubmitted || widget.mode == 'study';
      if (!_tabController.indexIsChanging) {
        _tabController.animateTo(index);
      }
    });
  }

  void _submitSession() {
    // Pause timer for current subject before submitting
    if (_currentActiveSubject != null) {
      _pauseSubjectTimer(_currentActiveSubject!);
    }

    final subjectResults = _mockSubjects.map((subject) {
      // Calculate score percentage
      final questions = subject["questions"] as List;
      final correctAnswers = questions.fold(0, (count, question) {
        final userAnswer = _answeredQuestions[subject["id"]]?[question["id"]];
        return count + (userAnswer == question["correctAnswer"] ? 1 : 0);
      });
      final score = (correctAnswers / questions.length) * 100;
      
      // Get tracked time spent
      final timeSpent = _subjectTimeSpent[subject["id"]] ?? Duration.zero;
      
      return SubjectResult(
        subject: subject["name"],
        score: score,
        timeSpent: timeSpent.inSeconds / 60, // convert to minutes
      );
    }).toList();

    setState(() {
      _sessionSubmitted = true;
      _showCorrectAnswer = true;
      if (widget.mode == 'practice' || widget.mode == 'mock') {
        _timer.cancel();
      }
    });

    Navigator.push(context, MaterialPageRoute(builder: (context) => ResultPage(
      isPracticeMode: widget.mode == 'practice',
      userData: const {
        'name': 'John Doe',
        'examNumber': 'PR20230001',
        'admissionType': 'UTME',
        'state': 'Lagos',
        'lga': 'Ikeja',
        'phone': '08012345678',
      },
      subjectResults: subjectResults,
    )));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Map<String, dynamic> get _currentSubject => _mockSubjects[_currentSubjectIndex];
  int get _totalQuestions => (_currentSubject["questions"] as List).length;
  Map<String, dynamic> get _currentQuestionData => 
      _currentSubject["questions"][_currentQuestion - 1];

  Widget _buildQuestionNumberButton(int questionNumber) {
    final isAnswered = _answeredQuestions[_currentSubject["id"]]?[questionNumber] != null;
    final isCurrent = _currentQuestion == questionNumber;
    final isCorrect = _answeredQuestions[_currentSubject["id"]]?[questionNumber] == 
        _currentSubject["questions"][questionNumber - 1]["correctAnswer"];
    
    Color? backgroundColor;
    Color borderColor = Theme.of(context).dividerColor;

    if (isCurrent) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
      borderColor = Theme.of(context).colorScheme.primary;
    } else if (_sessionSubmitted) {
      if (isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
      } else if (isAnswered) {
        backgroundColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
      }
    } else if (isAnswered) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.05);
      borderColor = Theme.of(context).colorScheme.primary.withOpacity(0.5);
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
        ),
        onPressed: () {
          setState(() {
            _currentQuestion = questionNumber;
            _selectedAnswer = _answeredQuestions[_currentSubject["id"]]?[questionNumber];
            _showExplanation = false;
            _showCorrectAnswer = _sessionSubmitted;
          });
        },
        child: Text(questionNumber.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: isMobile
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentSubject["name"]),
                  Text(
                    widget.mode == 'study' 
                      ? 'Study Mode' 
                      : widget.mode == 'practice' 
                        ? 'Practice Mode' 
                        : 'Mock Exam',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
        bottom: isMobile
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
                    tabs: _mockSubjects.map((subject) {
                      return Tab(
                        text: subject["name"],
                      );
                    }).toList(),
                  ),
                ),
              )
            : null,
        actions: [
          if (widget.mode == 'practice' || widget.mode == 'mock') ...[
            Row(
              children: [
                const Icon(Icons.timer, size: 16),
                const SizedBox(width: 4),
                Text(_formatDuration(_remainingTime)),
                const SizedBox(width: 16),
              ],
            ),
          ],
          OutlinedButton(
            onPressed: _sessionSubmitted 
                ? null 
                : () => _submitSession(),
            child: const Text("Submit"),
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (isMobile) ...[
                        const SizedBox(height: 8),
                        Text(
                          _currentSubject["name"],
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Badge(
                                    label: Text("Question $_currentQuestion"),
                                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: LinearProgressIndicator(
                                      value: _currentQuestion / _totalQuestions,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _currentQuestionData["question"],
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                children: (_currentQuestionData["options"] as List).map<Widget>((option) {
                                  final isSelected = _selectedAnswer == option["id"];
                                  final isCorrect = option["id"] == _currentQuestionData["correctAnswer"];
                                  final showAsCorrect = (_showCorrectAnswer || (widget.mode == 'study' && isSelected)) && isCorrect;
                                  final showAsIncorrect = (_showCorrectAnswer || widget.mode == 'study') && isSelected && !isCorrect;
                                  final isDisabled = (widget.mode == 'study' && _selectedAnswer != null) || 
                                      (_sessionSubmitted && widget.mode != 'study');
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: isDisabled ? null : () => _handleAnswerSelect(option["id"]),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: showAsCorrect
                                                ? Colors.green
                                                : showAsIncorrect
                                                    ? Colors.red
                                                    : isSelected
                                                        ? Theme.of(context).colorScheme.primary
                                                        : Theme.of(context).dividerColor,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          color: showAsCorrect
                                              ? Colors.green.withOpacity(0.1)
                                              : showAsIncorrect
                                                  ? Colors.red.withOpacity(0.1)
                                                  : isSelected
                                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                                      : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: showAsCorrect
                                                      ? Colors.green
                                                      : showAsIncorrect
                                                          ? Colors.red
                                                          : isSelected
                                                              ? Theme.of(context).colorScheme.primary
                                                              : Theme.of(context).dividerColor,
                                                ),
                                              ),
                                              child: showAsCorrect
                                                  ? const Icon(Icons.check, size: 16, color: Colors.green)
                                                  : showAsIncorrect
                                                      ? const Icon(Icons.close, size: 16, color: Colors.red)
                                                      : isSelected
                                                          ? Icon(
                                                              Icons.circle,
                                                              size: 16,
                                                              color: Theme.of(context).colorScheme.primary,
                                                            )
                                                          : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                "${option["id"]}. ${option["text"]}",
                                                style: TextStyle(
                                                  color: showAsCorrect
                                                      ? Colors.green
                                                      : showAsIncorrect
                                                          ? Colors.red
                                                          : isSelected
                                                              ? Theme.of(context).colorScheme.primary
                                                              : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showExplanation || (widget.mode == 'study' && _selectedAnswer != null)) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Explanation",
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentQuestionData["explanation"],
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            onPressed: _currentQuestion == 1 ? null : _handlePreviousQuestion,
                            child: const Text("Previous"),
                          ),
                          Row(
                            children: [
                              if (widget.mode == 'study' || _sessionSubmitted) ...[
                                OutlinedButton(
                                  onPressed: () => (widget.mode == 'study' && !_showExplanation)? null : setState(() => _showExplanation = !_showExplanation),
                                  child: Text(_showExplanation ? "Hide Explanation" : "Show Explanation"),
                                ),
                                const SizedBox(width: 8),
                              ],
                              ElevatedButton(
                                onPressed: _currentQuestion == _totalQuestions 
                                    ? (_sessionSubmitted || widget.mode == 'study') 
                                        ? null 
                                        : () => _submitSession()
                                    : _handleNextQuestion,
                                child: Text(
                                  _currentQuestion == _totalQuestions && !_sessionSubmitted && widget.mode != 'study'
                                      ? 'Submit'
                                      : 'Next',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isMobile) const SizedBox(height: 72),
                    ],
                  ),
                ),
              ),
              // Sidebar - hidden on mobile
              if (!isMobile) ...[
                Container(
                  width: 200,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Subjects",
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Column(
                                children: _mockSubjects.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final subject = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: _currentSubjectIndex == index
                                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                            : null,
                                        side: BorderSide(
                                          color: _currentSubjectIndex == index
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      onPressed: () => _handleSubjectChange(index),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.book_outlined, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              subject["name"],
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Questions",
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(_totalQuestions, (index) {
                                  return _buildQuestionNumberButton(index + 1);
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          // Mobile question navigation (bottom sheet)
          if (isMobile) ...[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_totalQuestions, (index) {
                    return _buildQuestionNumberButton(index + 1);
                  }),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}