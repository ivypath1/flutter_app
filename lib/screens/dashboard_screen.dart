import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ivy_path/models/result_model.dart';
import 'package:ivy_path/models/subject_model.dart';
import 'package:ivy_path/providers/auth_provider.dart';
import 'package:ivy_path/widgets/layout_widget.dart';
import 'package:provider/provider.dart';
import 'package:ivy_path/services/records_service.dart';
import 'package:ivy_path/services/subject_service.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<PracticeRecord> _records = [];
  List<Subject> _subjects = [];
  final RecordsService _recordsService = RecordsService();
  final SubjectService _subjectService = SubjectService();
  

  @override
  void initState() {
    super.initState();
    _recordsService.syncDraftAndFetchRecords();
    _subjectService.getSubjects();
  }
  

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isDesktop = mediaWidth >= 1100;
    final isTablet = mediaWidth >= 600;
    final auth = context.watch<AuthProvider>();
    final user = auth.authData?.user;


    return ValueListenableBuilder(
      valueListenable: Hive.box<PracticeRecord>('results').listenable(),
      builder: (context, Box<PracticeRecord> recordsBox, _) {
        _records = recordsBox.values.toList();
        return ValueListenableBuilder<Box<Subject>>(
          valueListenable: Hive.box<Subject>('subjects').listenable(),
          builder: (context, subjectsBox, _) {
            _subjects = subjectsBox.values.toList();
            return Scaffold(
              drawer: !isDesktop ? const AppDrawer(activeIndex: 1) : null,
              body: Row(
                children: [
                  if (isDesktop) const AppDrawer(activeIndex: 1),
                  if (isTablet && !isDesktop) const IvyNavRail(),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        IvyAppBar(
                          title: 'Dashboard',
                          showMenuButton: !isDesktop,
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                WelcomeSection(user: user),
                                const SizedBox(height: 32),
                                ProgressSummary(
                                  isWideScreen: isTablet,
                                  records: _records,
                                ),
                                const SizedBox(height: 32),
                                QuickActions(isWideScreen: isTablet),
                                const SizedBox(height: 32),
                                PerformanceChart(records: _records),
                                const SizedBox(height: 32),
                                SubjectPerformance(records: _records, subjects: _subjects),
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
        );
      }
    );
  }
}

class WelcomeSection extends StatelessWidget {
  final dynamic user;

  const WelcomeSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${user?.firstName ?? "User"}!',
          style: theme.textTheme.headlineLarge,
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 8),
        Text(
          'Track your progress and stay focused on your goals',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ).animate().fadeIn().slideX(begin: -0.2, delay: 200.ms),
      ],
    );
  }
}

class ProgressSummary extends StatelessWidget {
  final bool isWideScreen;
  final List<PracticeRecord> records;

  const ProgressSummary({
    super.key,
    required this.isWideScreen,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final totalSessions = records.length;
    final completedSessions = records.where((r) => !r.isDraft).length;
    final averageScore = records.isEmpty ? 0.0 : records
        .expand((r) => r.results)
        .map((r) => r.score)
        .reduce((a, b) => a + b) / records.length;
    final totalTime = records
        .expand((r) => r.results)
        .map((r) => r.timeSpent)
        .fold(0.0, (a, b) => a + b);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _ProgressCard(
          title: 'Total Sessions',
          value: totalSessions.toString(),
          subtitle: '$completedSessions completed',
          icon: Icons.assignment,
          width: isWideScreen ? 300 : double.infinity,
          color: Colors.blue,
        ),
        _ProgressCard(
          title: 'Average Score',
          value: '${averageScore.toStringAsFixed(1)}%',
          subtitle: 'Keep improving!',
          icon: Icons.trending_up,
          width: isWideScreen ? 300 : double.infinity,
          color: Colors.green,
        ),
        _ProgressCard(
          title: 'Study Time',
          value: '${(totalTime / 60).toStringAsFixed(1)}h',
          subtitle: '${totalTime.toStringAsFixed(0)} minutes',
          icon: Icons.timer,
          width: isWideScreen ? 300 : double.infinity,
          color: Colors.orange,
        ),
      ],
    );
  }
}

class QuickActions extends StatelessWidget {
  final bool isWideScreen;

  const QuickActions({super.key, required this.isWideScreen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _ActionCard(
              title: 'Start Practice Session',
              description: 'Practice questions from various subjects',
              icon: Icons.play_circle,
              onTap: () => Navigator.pushNamed(context, '/practice'),
              width: isWideScreen ? 300 : double.infinity,
            ),
            _ActionCard(
              title: 'View Study Materials',
              description: 'Access premium study resources',
              icon: Icons.book,
              onTap: () => Navigator.pushNamed(context, '/materials'),
              width: isWideScreen ? 300 : double.infinity,
            ),
            _ActionCard(
              title: 'Join Discussion',
              description: 'Connect with other students',
              icon: Icons.forum,
              onTap: () => Navigator.pushNamed(context, '/forum'),
              width: isWideScreen ? 300 : double.infinity,
            ),
          ],
        ),
      ],
    );
  }
}

class PerformanceChart extends StatelessWidget {
  final List<PracticeRecord> records;

  const PerformanceChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeklyData = _getWeeklyPerformance();
    
    // Handle empty data case
    if (weeklyData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Trend',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              const SizedBox(
                height: 300,
                child: Center(
                  child: Text(
                    'No performance data available yet.\nStart practicing to see your progress!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trend',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < weeklyData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                weeklyData[index]['week'] as String,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                  ),
                  minX: 0,
                  maxX: (weeklyData.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['score'] as double,
                        );
                      }).toList(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
                          radius: 3,
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getWeeklyPerformance() {
    if (records.isEmpty) return [];
    
    final weeklyScores = <String, List<double>>{};
    final now = DateTime.now();
    
    // Group scores by week
    for (var record in records) {
      if (record.results.isEmpty) continue;
      
      final recordDate = record.timestamp;
      // Calculate week start (Monday)
      final weekStart = recordDate.subtract(Duration(days: recordDate.weekday - 1));
      final weekKey = DateFormat('MMM d').format(weekStart);
      
      // Calculate average score for this record
      final avgScore = record.results
          .map((r) => r.score)
          .fold(0.0, (sum, score) => sum + score) / record.results.length;
      
      weeklyScores.putIfAbsent(weekKey, () => []);
      weeklyScores[weekKey]!.add(avgScore);
    }
    
    // Convert to list and calculate weekly averages
    final weeklyData = weeklyScores.entries.map((entry) {
      final weekAverage = entry.value.fold(0.0, (sum, score) => sum + score) / entry.value.length;
      return {
        'week': entry.key,
        'score': weekAverage.clamp(0.0, 100.0), // Ensure score is within 0-100 range
      };
    }).toList();
    
    // Sort by date (approximate sorting by week string)
    weeklyData.sort((a, b) {
      try {
        final dateA = DateFormat('MMM d').parse(a['week'] as String);
        final dateB = DateFormat('MMM d').parse(b['week'] as String);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0; // If parsing fails, maintain current order
      }
    });
    
    // Limit to last 8 weeks for better visualization
    if (weeklyData.length > 8) {
      return weeklyData.sublist(weeklyData.length - 8);
    }
    
    return weeklyData;
  }
}


class SubjectPerformance extends StatelessWidget {
  final List<PracticeRecord> records;
  final List<Subject> subjects;

  const SubjectPerformance({super.key, required this.records, required this.subjects});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectScores = _getSubjectScores();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Performance',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            ...subjectScores.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('${entry.value.toStringAsFixed(1)}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: entry.value / 100,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(entry.value),
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, double> _getSubjectScores() {
    final scores = <String, List<double>>{};
    
    for (var record in records) {
      for (var result in record.results) {
        final subject = subjects.firstWhere(
          (s) => s.id == result.subjectId,
          orElse: () => Subject(id: result.subjectId, name: 'Unknown', sections: []),
        );
        scores.putIfAbsent(subject.name, () => []);
        scores[subject.name]!.add(result.score);
      }
    }
    
    return scores.map((key, value) {
      return MapEntry(
        key,
        value.reduce((a, b) => a + b) / value.length,
      );
    });
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final double width;
  final Color color;

  const _ProgressCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.width,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final double width;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, delay: 400.ms);
  }
}