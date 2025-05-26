import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ivy_path/models/result_model.dart';
import 'package:ivy_path/screens/result_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ivy_path/models/subject_model.dart';

class SessionPage extends StatefulWidget {
  final String mode; // 'study', 'practice', or 'mock'
  final double duration; // in minutes
  final bool shuffleOptions;
  final bool shuffleQuestions;
  final List<Map<String, dynamic>> subjects;
  final PracticeRecord? fromRecord;
  
  const SessionPage({
    super.key, 
    required this.mode,
    required this.duration,
    this.shuffleOptions = false,
    this.shuffleQuestions = false,
    required this.subjects,
    this.fromRecord,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> with SingleTickerProviderStateMixin {
  int _currentSubjectIndex = 0;
  int _currentQuestion = 1;
  String? _selectedAnswer;
  final Map<int, Map<int, List>> _answeredQuestions = {};
  bool _showExplanation = false;
  late TabController _tabController;
  bool _sessionSubmitted = false;
  Duration _remainingTime = Duration.zero;
  late Timer _timer;
  bool _showCorrectAnswer = false;
  bool _showFullQuestionSheet = false;
  final practiceRecordBox = Hive.openBox<PracticeRecord>('results');

  // Time tracking variables
  final Map<String, Duration> _subjectTimeSpent = {};
  final Map<String, DateTime?> _subjectTimers = {};
  String? _currentActiveSubject;

  // Hive data
  List<Subject> _subjects = [];
  Map<int, List<Question>> _questions = {};
  PracticeRecord? _currentPracticeRecord;

  @override
  void initState() {
    super.initState();
    
    // Initialize from record if provided
    if (widget.fromRecord != null) {
      _currentPracticeRecord = widget.fromRecord;
      _sessionSubmitted = true;
      _showCorrectAnswer = true;
      
      // Load answers from record
      for (var result in widget.fromRecord!.results) {
        _answeredQuestions[result.subjectId] = {};
        result.answers.forEach((key, value) {
          _answeredQuestions[result.subjectId]![key] = value;
        });
      }
    }
    
    _loadData();
    _tabController = TabController(
      length: widget.subjects.length,
      vsync: this,
      initialIndex: _currentSubjectIndex,
    );
    _tabController.addListener(_handleTabChange);
    
    // Initialize timer if in practice or mock mode and not viewing a record
    if ((widget.mode == 'practice' || widget.mode == 'mock') && widget.fromRecord == null) {
      _remainingTime = Duration(minutes: widget.duration.toInt());
      _startTimer();
    }

    // Initialize time tracking for all subjects
    for (var subject in widget.subjects) {
      _subjectTimeSpent[subject["id"].toString()] = Duration.zero;
      _subjectTimers[subject["id"].toString()] = null;
    }

    // Start timer for first subject if not viewing a record
    if (widget.fromRecord == null) {
      _currentActiveSubject = widget.subjects[_currentSubjectIndex]["id"].toString();
      _subjectTimers[_currentActiveSubject!] = DateTime.now();
    }
  }

  Future<void> _loadData() async {
    final subjectsBox = await Hive.openBox<Subject>('subjects');
    final questionsBox = await Hive.openBox<Question>('questions');

    // Load subjects
    _subjects = widget.subjects.map((subjectConfig) {
      final subject = subjectsBox.get(subjectConfig['id']);
      
      if (subject == null) {
        throw Exception('Subject ${subjectConfig['id']} not found in Hive');
      }
      return subject;
    }).toList();

    // Load questions for each subject based on config
    for (var config in widget.subjects) {
      final int subjectId = config['id'];
      final int sectionId = config['section'];
      final int questionCount = config['questions'];

      final subject = subjectsBox.get(subjectId);
      if (subject == null) continue;

      // Filter questions by section
      List<Question> subjectQuestions = [];

      if (sectionId == 0) {
        // Get all sections' questions
        for (var section in subject.sections) {
          subjectQuestions.addAll(
            questionsBox.values.where((q) => q.sectionId == section.id),
          );
        }
      } else {
        // Get specific section's questions
        subjectQuestions.addAll(
          questionsBox.values.where((q) => q.sectionId == sectionId),
        );
      }

      // Shuffle questions if needed and not viewing a record
      if (widget.shuffleQuestions && widget.fromRecord == null) {
        subjectQuestions.shuffle();
      }

      // Limit to required number of questions
      final selectedQuestions = subjectQuestions.take(questionCount).toList();

      // Shuffle options if needed and not viewing a record
      if (widget.shuffleOptions && widget.fromRecord == null) {
        for (var question in selectedQuestions) {
          question.options.shuffle();
        }
      }

      // Add to _questions map
      _questions[subjectId] = selectedQuestions;

      // Initialize default answers for all questions in this subject if not viewing a record
      if (widget.fromRecord == null) {
        final defaultAnswers = <int, List>{};
        for (var question in selectedQuestions) {
          defaultAnswers[question.id] = [question.id, '']; // [questionId, empty answer]
        }
        _answeredQuestions[subjectId] = defaultAnswers;
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    if ((widget.mode == 'practice' || widget.mode == 'mock') && _timer.isActive) {
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
      _answeredQuestions[_currentSubject["id"]]?[_currentQuestionData?.id ?? 0] = [_currentQuestionData?.id ?? 0, value];

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
        _selectedAnswer = _answeredQuestions[_currentSubject["id"]]?[_currentQuestionData?.id ?? 0]?[1];
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
        _selectedAnswer = _answeredQuestions[_currentSubject["id"]]?[_currentQuestionData?.id ?? 0]?[1];
        _showExplanation = false;
        _showCorrectAnswer = _sessionSubmitted || widget.mode == 'study';
      });
    }
  }

  void _handleSubjectChange(int index) {
    final newSubjectId = widget.subjects[index]["id"];
    // Pause timer for current subject
    if (_currentActiveSubject != null) {
      _pauseSubjectTimer(_currentActiveSubject!);
    }
    
    // Start timer for new subject if not viewing a record
    if (widget.fromRecord == null) {
      _startSubjectTimer(newSubjectId.toString());
    }
    
    setState(() {
      _currentSubjectIndex = index;
      _currentQuestion = 1;
      _selectedAnswer = _answeredQuestions[newSubjectId]?[_questions[newSubjectId]?.first.id ?? 0]?[1];
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

    final subjectResults = _subjects.map((subject) {
      // Calculate score percentage
      final questions = _questions[subject.id] ?? [];
      final correctAnswers = questions.fold(0, (count, question) {
        final userAnswer = _answeredQuestions[subject.id]?[question.id]?[1];
        return count + (userAnswer == question.answer ? 1 : 0);
      });
      final score = (correctAnswers / questions.length) * 100;
      
      // Get tracked time spent
      final timeSpent = _subjectTimeSpent[subject.id.toString()] ?? Duration.zero;
      
      return Result(
        subjectId: subject.id, 
        answers: _answeredQuestions[subject.id]!, 
        score: score, 
        timeSpent: timeSpent.inSeconds / 60, // convert to minutes
      );
    }).toList();

    // Create a new PracticeRecord
    _currentPracticeRecord = PracticeRecord(
      id: DateTime.now().millisecondsSinceEpoch,
      duration: widget.duration,
      mode: widget.mode,
      isDraft: false,
      results: subjectResults,
    );

    // Save to Hive
    practiceRecordBox.then((box) {
      box.add(_currentPracticeRecord!);
    });

    setState(() {
      _sessionSubmitted = true;
      _showCorrectAnswer = true;
      if (widget.mode == 'practice' || widget.mode == 'mock') {
        _timer.cancel();
      }
    });
    _viewResults();
  }

  void _viewResults() {
    if (_currentPracticeRecord == null) return;
    
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
      subjectResults: _currentPracticeRecord!.results.map((result) => SubjectResult(
        subject: _subjects.firstWhere((s) => s.id == result.subjectId).name,
        score: result.score,
        timeSpent: result.timeSpent,
      )).toList(),
    )));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Map<String, dynamic> get _currentSubject => widget.subjects[_currentSubjectIndex];
  int get _totalQuestions => (_questions[_currentSubject["id"]] ?? []).length;
  Question? get _currentQuestionData => 
      _questions[_currentSubject["id"]]?[_currentQuestion - 1];

  Widget _buildQuestionNumberButton(int questionNumber) {
    final questionId = _questions[_currentSubject["id"]]?[questionNumber - 1]?.id ?? 0;
    final isAnswered = _answeredQuestions[_currentSubject["id"]]?[questionId]?[1] != null && 
                      _answeredQuestions[_currentSubject["id"]]?[questionId]?[1] != '';
    final isCurrent = _currentQuestion == questionNumber;

    final correctAnswer = _questions[_currentSubject["id"]]?.firstWhere(
      (q) => q.id == questionId,
      orElse: () => Question(id: -1, question: '', options: [], answer: '', solution: '', sectionId: -1),
    ).answer;
    final userAnswer = _answeredQuestions[_currentSubject["id"]]?[questionId]?[1];
    final isCorrect = userAnswer == correctAnswer;

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
            _selectedAnswer = _answeredQuestions[_currentSubject["id"]]?[questionId]?[1];
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
                    tabs: _subjects.map((subject) {
                      return Tab(
                        text: subject.name,
                      );
                    }).toList(),
                  ),
                ),
              )
            : null,
        actions: [
          if (widget.mode == 'practice' || widget.mode == 'mock') ...[
            if (widget.fromRecord == null) // Only show timer for new sessions
              Row(
                children: [
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 4),
                  Text(_formatDuration(_remainingTime)),
                  const SizedBox(width: 16),
                ],
              ),
          ],
          _sessionSubmitted
              ? ElevatedButton(
                  onPressed: _viewResults,
                  child: const Text("View Results"),
                )
              : OutlinedButton(
                  onPressed: _submitSession,
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
                          _currentSubject["name"] ?? '',
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
                              MathContentWidget(content: _currentQuestionData!.question),
                              const SizedBox(height: 16),
                              Column(
                                children: (_currentQuestionData?.options as List).map<Widget>((option) {
                                  final isSelected = _selectedAnswer == option["id"];
                                  final isCorrect = option["id"] == _currentQuestionData?.answer;
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
                                  _currentQuestionData!.solution,
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
                      // Mobile question navigation (bottom sheet)
                      if (isMobile) ...[
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(_totalQuestions, (index) {
                                return _buildQuestionNumberButton(index + 1);
                              }),
                            ),
                          ),
                        )
                      ]
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
                                children: _subjects.asMap().entries.map((entry) {
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
                                              subject.name,
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
        ],
      ),
    );
  }
}

class MathContentWidget extends StatelessWidget {
  final String content;

  const MathContentWidget({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    // Check for math content
    if (content.contains(r'$$') || content.contains(r'$')) {
      return MathRenderer(mathText: content);
    } 
    // Check for markdown content
    else if (content.contains('|') || 
             content.contains('#') || 
             content.contains('*') ||
             content.contains('```')) {
      return Markdown(
        data: content,
        selectable: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      );
    } 
    // Plain text
    else {
      return Text(content, style: const TextStyle(fontSize: 16));
    }
  }
}

class MathRenderer extends StatelessWidget {
  final String mathText;

  const MathRenderer({super.key, required this.mathText});

  @override
  Widget build(BuildContext context) {
    // Split the text by newlines first to handle paragraphs
    final paragraphs = mathText.split(r'\n');
    List<Widget> paragraphWidgets = [];

    for (String paragraph in paragraphs) {
      if (paragraph.isEmpty) {
        // Add an empty space for blank lines
        paragraphWidgets.add(const SizedBox(height: 16));
        continue;
      }

      // Process each paragraph separately
      List<InlineSpan> spans = [];
      String remainingText = paragraph;
      
      while (remainingText.isNotEmpty) {
        // Check for display math first ($$...$$)
        final displayMathMatch = RegExp(r'\$\$(.*?)\$\$', dotAll: true).firstMatch(remainingText);
        
        if (displayMathMatch != null && displayMathMatch.start == 0) {
          // Handle display math at the beginning of the paragraph
          // For display math, we want to create a separate widget
          if (spans.isNotEmpty) {
            // Add the accumulated text spans as a RichText widget
            paragraphWidgets.add(RichText(text: TextSpan(children: spans, style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 16
                          ),)));
            spans = [];
          }
          
          String mathExpression = displayMathMatch.group(1)!.trim();
          paragraphWidgets.add(_buildDisplayMath(mathExpression));
          remainingText = remainingText.substring(displayMathMatch.end);
          continue;
        } 
        
        // Check for inline math ($...$)
        final inlineMathMatch = RegExp(r'\$(.*?)\$').firstMatch(remainingText);
        
        if (inlineMathMatch != null) {
          // Add text before the math expression as a TextSpan
          if (inlineMathMatch.start > 0) {
            final textBefore = remainingText.substring(0, inlineMathMatch.start);
            spans.add(TextSpan(text: textBefore));
          }
          
          // Add the math expression as an inline widget span
          String mathExpression = inlineMathMatch.group(1)!;
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _buildInlineMath(mathExpression),
          ));
          
          // Update remaining text
          remainingText = remainingText.substring(inlineMathMatch.end);
        } else {
          // No more math expressions, add the remaining text
          spans.add(TextSpan(text: remainingText));
          break;
        }
      }

      // Add any remaining spans for this paragraph
      if (spans.isNotEmpty) {
        paragraphWidgets.add(RichText(
          text: TextSpan(
            children: spans,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 16),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphWidgets,
    );
  }
  
  // Helper for display math
  Widget _buildDisplayMath(String expression) {
    // Clean the expression
    expression = _cleanMathExpression(expression);
    
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Math.tex(
        expression,
        textStyle: const TextStyle(fontSize: 18),
        mathStyle: MathStyle.display,
        onErrorFallback: (FlutterMathException e) => 
            Text("Math error: ${e.message}", style: const TextStyle(color: Colors.red)),
      ),
    );
  }
  
  // Helper for inline math
  Widget _buildInlineMath(String expression) {
    // Clean the expression
    expression = _cleanMathExpression(expression);
    
    return Math.tex(
      expression,
      textStyle: const TextStyle(fontSize: 16),
      onErrorFallback: (FlutterMathException e) => 
          Text("Math error: ${e.message}", style: const TextStyle(color: Colors.red, fontSize: 14)),
    );
  }
  
  // Clean math expressions
  String _cleanMathExpression(String expression) {
    // Replace double backslashes with single ones for TeX
    return expression.replaceAll(r'\\', r'\');
  }
}