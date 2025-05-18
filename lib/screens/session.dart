import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  int _currentSubjectIndex = 0;
  int _currentQuestion = 1;
  String? _selectedAnswer;
  bool _showExplanation = false;
  bool _sessionEnded = false;
  bool _showResult = false;
  int _timeLeft = 1800; // 30 minutes in seconds
  late Timer _timer;

  final List<Subject> _subjects = [
    Subject(
      id: 1,
      name: 'Physics',
      questions: [
        Question(
          id: 1,
          question: 'What is the SI unit of force?',
          options: [
            {'id': 'A', 'text': 'Newton'},
            {'id': 'B', 'text': 'Joule'},
            {'id': 'C', 'text': 'Watt'},
            {'id': 'D', 'text': 'Pascal'},
          ],
          answer: 'A',
          solution: 'The SI unit of force is the Newton (N), named after Sir Isaac Newton.',
        ),
        Question(
          id: 2,
          question: 'Which law states that every action has an equal and opposite reaction?',
          options: [
            {'id': 'A', 'text': 'First Law of Motion'},
            {'id': 'B', 'text': 'Second Law of Motion'},
            {'id': 'C', 'text': 'Third Law of Motion'},
            {'id': 'D', 'text': 'Law of Gravitation'},
          ],
          answer: 'C',
          solution: 'Newton\'s Third Law of Motion states that for every action, there is an equal and opposite reaction.',
        ),
      ],
    ),
    Subject(
      id: 2,
      name: 'Chemistry',
      questions: [
        Question(
          id: 1,
          question: 'What is the atomic number of Carbon?',
          options: [
            {'id': 'A', 'text': '6'},
            {'id': 'B', 'text': '12'},
            {'id': 'C', 'text': '14'},
            {'id': 'D', 'text': '16'},
          ],
          answer: 'A',
          solution: 'Carbon has an atomic number of 6, meaning it has 6 protons in its nucleus.',
        ),
      ],
    ),
  ];

  final Map<String, Map<int, String>> _savedAnswers = {};
  final String _sessionMode = 'practice'; // 'practice', 'study', or 'mock'

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _handleSessionEnd();
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _handleAnswerSelect(String? value) {
    setState(() {
      _selectedAnswer = value;
      if (value != null) {
        _savedAnswers[_subjects[_currentSubjectIndex].id.toString()] ??= {};
        _savedAnswers[_subjects[_currentSubjectIndex].id.toString()]![_currentQuestion] = value;
      }
    });
  }

  void _handleNextQuestion() {
    if (_currentQuestion < _currentSubject.questions.length) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = _savedAnswers[_currentSubject.id.toString()]?[_currentQuestion];
        _showExplanation = false;
      });
    }
  }

  void _handlePreviousQuestion() {
    if (_currentQuestion > 1) {
      setState(() {
        _currentQuestion--;
        _selectedAnswer = _savedAnswers[_currentSubject.id.toString()]?[_currentQuestion];
        _showExplanation = false;
      });
    }
  }

  void _handleSubjectChange(int index) {
    setState(() {
      _currentSubjectIndex = index;
      _currentQuestion = 1;
      _selectedAnswer = _savedAnswers[_subjects[index].id.toString()]?[1];
      _showExplanation = false;
    });
  }

  void _handleSubmitSession() {
    setState(() {
      _sessionEnded = true;
      _showResult = true;
    });
    _timer.cancel();
  }

  void _handleSessionEnd() {
    _handleSubmitSession();
  }

  Subject get _currentSubject => _subjects[_currentSubjectIndex];
  Question get _currentQuestionData => _currentSubject.questions[_currentQuestion - 1];
  bool get _shouldShowAnswer => _sessionMode == 'study' || (_sessionMode == 'practice' && _sessionEnded);

  Widget _renderAnswerIndicator(String optionId) {
    if (!_shouldShowAnswer) return const SizedBox.shrink();
    
    final isCorrect = optionId == _currentQuestionData.answer;
    final isSelected = optionId == _selectedAnswer;
    
    if (isCorrect) {
      return const Icon(Icons.check, size: 16, color: Colors.green);
    } else if (isSelected && !isCorrect) {
      return const Icon(Icons.close, size: 16, color: Colors.red);
    }
    return const SizedBox.shrink();
  }

  Widget _renderQuestionNumber(int index) {
    final questionNumber = index + 1;
    final answer = _savedAnswers[_currentSubject.id.toString()]?[questionNumber];
    final isCorrect = answer == _currentSubject.questions[index].answer;
    
    Color? backgroundColor;
    Color? foregroundColor;
    Color? borderColor;
    
    if (questionNumber == _currentQuestion) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      foregroundColor = Theme.of(context).colorScheme.onPrimary;
    } else if (answer != null && _sessionEnded) {
      backgroundColor = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
      borderColor = isCorrect ? Colors.green : Colors.red;
      foregroundColor = Colors.black;
    } else if (answer != null) {
      backgroundColor = Colors.red.shade100;
      borderColor = Colors.red;
      foregroundColor = Colors.black;
    }
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: BorderSide(color: borderColor ?? Colors.grey.shade300),
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
      ),
      onPressed: () {
        setState(() {
          _currentQuestion = questionNumber;
          _selectedAnswer = answer;
          _showExplanation = false;
        });
      },
      child: Stack(
        children: [
          Center(child: Text(questionNumber.toString())),
          if (answer != null && _sessionEnded)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                isCorrect ? Icons.check : Icons.close,
                size: 12,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Session Results',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          
          // Score Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assessment, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Your Score',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CustomPaint(
                    size: const Size(150, 150),
                    painter: _ScorePainter(score: 75),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '75%',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Time Spent: 25m 30s',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Performance Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Performance Breakdown',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPerformanceRow('Overall Score', '15/20'),
                  _buildPerformanceRow('Total Time', '25m 30s'),
                  _buildPerformanceRow('Accuracy', '75%'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Detailed Results
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Detailed Results',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Subject')),
                      DataColumn(label: Text('Score', textAlign: TextAlign.end)),
                      DataColumn(label: Text('Time', textAlign: TextAlign.end)),
                    ],
                    rows: [
                      _buildDataRow('Physics', '8/10', '12m 45s'),
                      _buildDataRow('Chemistry', '7/10', '12m 45s'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _showResult = false),
                child: const Text('Back to Questions'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Navigate to new session
                },
                child: const Text('Start New Session'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  DataRow _buildDataRow(String subject, String score, String time) {
    return DataRow(
      cells: [
        DataCell(Text(subject)),
        DataCell(Text(score, textAlign: TextAlign.end)),
        DataCell(Text(time, textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _buildQuestionScreen() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(label: Text('Question $_currentQuestion')),
                            SizedBox(
                              width: 100, // Fixed width
                              child: LinearProgressIndicator(
                                value: _currentQuestion / _currentSubject.questions.length,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentQuestionData.question,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: _currentQuestionData.options.map((option) {
                            final isSelected = _selectedAnswer == option['id'];
                            final isCorrectAnswer = _shouldShowAnswer && option['id'] == _currentQuestionData.answer;
                            final isWrongAnswer = _shouldShowAnswer && isSelected && !isCorrectAnswer;
                            
                            return Card(
                              color: isCorrectAnswer
                                  ? Colors.green.shade50
                                  : isWrongAnswer
                                      ? Colors.red.shade50
                                      : isSelected
                                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                          : null,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: isCorrectAnswer
                                      ? Colors.green
                                      : isWrongAnswer
                                          ? Colors.red
                                          : isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: RadioListTile<String>(
                                title: Row(
                                  children: [
                                    Text('${option['id']}. '),
                                    Expanded(child: Text(option['text']!)),
                                    _renderAnswerIndicator(option['id']!),
                                  ],
                                ),
                                value: option['id']!,
                                groupValue: _selectedAnswer,
                                onChanged: _shouldShowAnswer ? null : _handleAnswerSelect,
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Explanation Card
                if (_showExplanation)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explanation',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(_currentQuestionData.solution),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),
                
                const SizedBox(height: 80), // Space for bottom navigation
              ],
            ),
          ),
        ),
        
        // Bottom navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: _handlePreviousQuestion,
                child: const Text('Previous'),
              ),
              if ((_sessionMode == 'study' || _sessionEnded) && !_showResult)
                OutlinedButton(
                  onPressed: () => setState(() => _showExplanation = !_showExplanation),
                  child: Text(_showExplanation ? 'Hide Explanation' : 'Show Explanation'),
                ),
              ElevatedButton(
                onPressed: _currentQuestion == _currentSubject.questions.length
                    ? _handleSubmitSession
                    : _handleNextQuestion,
                child: Text(_currentQuestion == _currentSubject.questions.length ? 'Submit' : 'Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Navigate back
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_sessionEnded ? 'Session Results' : _currentSubject.name),
            Text(
              _sessionEnded ? 'Completed' : '${_sessionMode} Mode',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (!_sessionEnded || !_showResult)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 20),
                  const SizedBox(width: 4),
                  Text(_formatTime(_timeLeft)),
                  if (_sessionMode != 'study')
                    const SizedBox(width: 16),
                  if (_sessionMode != 'study')
                    OutlinedButton(
                      onPressed: _handleSubmitSession,
                      child: Text(_sessionEnded ? 'View Results' : 'Submit Session'),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: _showResult ? _buildResultScreen() : _buildQuestionScreen(),
    );
  }
}

class Subject {
  final int id;
  final String name;
  final List<Question> questions;

  Subject({required this.id, required this.name, required this.questions});
}

class Question {
  final int id;
  final String question;
  final List<Map<String, String?>> options;
  final String answer;
  final String solution;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.solution,
  });
}

class _ScorePainter extends CustomPainter {
  final int score;
  
  _ScorePainter({required this.score});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    
    canvas.drawCircle(center, radius - 5, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * pi * (score / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}