import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ivy_path/models/result_model.dart';
import 'package:ivy_path/models/subject_model.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';
import 'package:ivy_path/widgets/layout_widget.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  List<PracticeRecord> _records = [];
  Map<int, Subject> _subjects = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final recordsBox = await Hive.openBox<PracticeRecord>('results');
      final subjectsBox = await Hive.openBox<Subject>('subjects');

      setState(() {
        _records = recordsBox.values.toList();
        _subjects = {
          for (var subject in subjectsBox.values) subject.id: subject
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _getSubjectName(int id) {
    return _subjects[id]?.name ?? 'Unknown Subject';
  }

  Map<int, List<double>> _getAverageScores() {
    final scores = <int, List<double>>{};
    for (var record in _records) {
      for (var result in record.results) {
        scores.putIfAbsent(result.subjectId, () => []);
        scores[result.subjectId]!.add(result.score);
      }
    }
    return scores;
  }

  Map<String, List<double>> _getScoresByMode() {
    final scores = <String, List<double>>{};
    for (var record in _records) {
      scores.putIfAbsent(record.mode, () => []);
      final avgScore = record.results.fold(0.0, (sum, r) => sum + r.score) / record.results.length;
      scores[record.mode]!.add(avgScore);
    }
    return scores;
  }

  List<Map<String, dynamic>> _getWeeklyPerformance() {
    // Group records by week
    final weeklyData = <String, List<double>>{};
    final now = DateTime.now();
    
    for (var record in _records) {
      final recordDate = record.timestamp ?? now;
      final weekStart = recordDate.subtract(Duration(days: recordDate.weekday - 1));
      final weekKey = '${weekStart.day}/${weekStart.month}';
      
      weeklyData.putIfAbsent(weekKey, () => []);
      final avgScore = record.results.fold(0.0, (sum, r) => sum + r.score) / record.results.length;
      weeklyData[weekKey]!.add(avgScore);
    }
    
    return weeklyData.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return {
        'week': entry.key,
        'score': avg,
        'sessions': entry.value.length,
      };
    }).toList();
  }

  Map<String, int> _getDifficultyDistribution() {
    final distribution = <String, int>{};
    for (var record in _records) {
      for (var result in record.results) {
        // Assuming difficulty is determined by score ranges
        String difficulty;
        if (result.score >= 80) {
          difficulty = 'Easy';
        } else if (result.score >= 60) {
          difficulty = 'Medium';
        } else {
          difficulty = 'Hard';
        }
        distribution[difficulty] = (distribution[difficulty] ?? 0) + 1;
      }
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isDesktop = mediaWidth >= 1100;
    final isTablet = mediaWidth >= 600;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
      drawer: !isDesktop ? const AppDrawer() : null,
      body: Row(
        children: [
          if (isDesktop) const AppDrawer(),
          if (isTablet && !isDesktop) const IvyNavRail(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                IvyAppBar(
                  title: 'Performance Analytics',
                  showMenuButton: !isDesktop,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverallStats(mediaWidth),
                        SizedBox(height: mediaSetup(mediaWidth, sm: 24, md: 32, lg: 40)),
                        _buildMainCharts(mediaWidth),
                        SizedBox(height: mediaSetup(mediaWidth, sm: 24, md: 32, lg: 40)),
                        _buildSecondaryCharts(mediaWidth),
                        SizedBox(height: mediaSetup(mediaWidth, sm: 24, md: 32, lg: 40)),
                        _buildInsightsSection(mediaWidth),
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

  Widget _buildOverallStats(double mediaWidth) {
    final totalSessions = _records.length;
    final completedSessions = _records.where((r) => !r.isDraft).length;
    // Handle empty records case
    final averageScore = _records.isEmpty ? 0.0 : _records
        .expand((r) => r.results)
        .map((r) => r.score)
        .fold(0.0, (a, b) => a + b) / _records.expand((r) => r.results).length;
    
    final totalTime = _records
        .expand((r) => r.results)
        .map((r) => r.timeSpent)
        .fold(0.0, (a, b) => a + b);

    // Calculate completion rate safely
    final completionRate = totalSessions == 0 ? 0 : 
        ((completedSessions / totalSessions) * 100).round();

    return Wrap(
      spacing: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32),
      runSpacing: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32),
      children: [
        _StatCard(
          title: 'Total Sessions',
          value: totalSessions.toString(),
          icon: Icons.assignment,
          width: mediaSetup(mediaWidth, sm: double.infinity, md: 200, lg: 250),
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Completed Sessions',
          value: '$completedSessions',
          subtitle: '$completionRate% completion rate',
          icon: Icons.check_circle,
          width: mediaSetup(mediaWidth, sm: double.infinity, md: 200, lg: 250),
          color: Colors.green,
        ),
        _StatCard(
          title: 'Average Score',
          value: '${averageScore.toStringAsFixed(1)}%',
          icon: Icons.score,
          width: mediaSetup(mediaWidth, sm: double.infinity, md: 200, lg: 250),
          color: Colors.orange,
        ),
        _StatCard(
          title: 'Total Study Time',
          value: '${(totalTime / 60).toStringAsFixed(1)}h',
          subtitle: '${totalTime.toStringAsFixed(0)} minutes',
          icon: Icons.timer,
          width: mediaSetup(mediaWidth, sm: double.infinity, md: 200, lg: 250),
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMainCharts(double mediaWidth) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSubjectRadarChart()),
            if (mediaWidth >= 1024) const SizedBox(width: 24),
            if (mediaWidth >= 1024) 
              Expanded(child: _buildPerformanceTrendChart()),
          ],
        ),
        const SizedBox(height: 24),
        if (mediaWidth < 1024) _buildPerformanceTrendChart(),
      ],
    );
  }

  Widget _buildSecondaryCharts(double mediaWidth) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDifficultyDistributionChart()),
            if (mediaWidth >= 1024) const SizedBox(width: 24),
            if (mediaWidth >= 1024)
              Expanded(child: _buildTimeSpentPieChart()),
          ],
        ),
        const SizedBox(height: 24),
        if (mediaWidth < 1024) _buildTimeSpentPieChart(),
        if (mediaWidth < 1024) const SizedBox(height: 24),
        _buildWeeklyHeatmapChart(),
      ],
    );
  }

  Widget _buildSubjectRadarChart() {
  final scores = _getAverageScores();
  
  // Need at least 3 subjects for radar chart
  if (scores.length < 3) {
    return _ChartCard(
      title: 'Subject Performance Radar',
      height: 350,
      chart: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assessment_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Need at least 3 subjects',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'for radar chart display',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  final maxScore = 100.0;
  
  return _ChartCard(
    title: 'Subject Performance Radar',
    height: 350,
    chart: RadarChart(
      RadarChartData(
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: Colors.grey, width: 1),
        titlePositionPercentageOffset: 0.2,
        titleTextStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
        getTitle: (index, angle) {
          final subjectIds = scores.keys.toList();
          if (index < subjectIds.length) {
            return RadarChartTitle(
              text: _getSubjectName(subjectIds[index]).split(' ').first,
              angle: angle,
            );
          }
          return const RadarChartTitle(text: '');
        },
        dataSets: [
          RadarDataSet(
            fillColor: Colors.blue.withOpacity(0.2),
            borderColor: Colors.blue,
            entryRadius: 3,
            dataEntries: scores.entries.map((entry) {
              final avg = entry.value.isEmpty ? 0.0 : 
                  entry.value.reduce((a, b) => a + b) / entry.value.length;
              return RadarEntry(value: avg);
            }).toList(),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPerformanceTrendChart() {
    final weeklyData = _getWeeklyPerformance();
    
    return _ChartCard(
      title: 'Performance Trend Over Time',
      height: 350,
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 10,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < weeklyData.length) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        weeklyData[index]['week'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
                reservedSize: 42,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d)),
          ),
          minX: 0,
          maxX: weeklyData.length.toDouble() - 1,
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: weeklyData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value['score']);
              }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue,
                  Colors.purple,
                ],
              ),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: Colors.blue,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.purple.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyDistributionChart() {
    final distribution = _getDifficultyDistribution();
    final colors = [Colors.green, Colors.orange, Colors.red];
    
    return _ChartCard(
      title: 'Question Difficulty Distribution',
      height: 300,
      chart: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 60,
          sections: distribution.entries.map((entry) {
            final index = distribution.keys.toList().indexOf(entry.key);
            final total = distribution.values.reduce((a, b) => a + b);
            final percentage = (entry.value / total * 100);
            
            return PieChartSectionData(
              color: colors[index % colors.length],
              value: entry.value.toDouble(),
              title: '${percentage.round()}%',
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              badgeWidget: _Badge(
                entry.key,
                size: 40,
                borderColor: colors[index % colors.length],
              ),
              badgePositionPercentageOffset: .98,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimeSpentPieChart() {
    final timeSpent = <int, double>{};
    for (var record in _records) {
      for (var result in record.results) {
        timeSpent[result.subjectId] = 
            (timeSpent[result.subjectId] ?? 0) + result.timeSpent;
      }
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return _ChartCard(
      title: 'Time Distribution by Subject',
      height: 300,
      chart: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: timeSpent.entries.map((entry) {
            final index = timeSpent.keys.toList().indexOf(entry.key);
            final total = timeSpent.values.reduce((a, b) => a + b);
            final percentage = (entry.value / total * 100);
            
            return PieChartSectionData(
              color: colors[index % colors.length],
              value: entry.value,
              title: '${(entry.value / 60).toStringAsFixed(1)}h',
              radius: 90,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWeeklyHeatmapChart() {
    // Create a simple heatmap representation using containers
    final weeklyData = _getWeeklyPerformance();
    
    return _ChartCard(
      title: 'Weekly Activity Heatmap',
      height: 200,
      chart: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 28, // 4 weeks
        itemBuilder: (context, index) {
          final intensity = (index % weeklyData.length) / weeklyData.length;
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2 + (intensity * 0.8)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  color: intensity > 0.5 ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightsSection(double mediaWidth) {
  final scores = _getAverageScores();
  
  // Return empty container if no data
  if (scores.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text('No performance data available'),
    );
  }

  // Safely find best and worst subjects
  final bestSubject = scores.entries.reduce((a, b) => 
      (a.value.reduce((x, y) => x + y) / a.value.length) > 
      (b.value.reduce((x, y) => x + y) / b.value.length) ? a : b);
  
  final worstSubject = scores.entries.reduce((a, b) => 
      (a.value.reduce((x, y) => x + y) / a.value.length) < 
      (b.value.reduce((x, y) => x + y) / b.value.length) ? a : b);


    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Insights',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _InsightTile(
              icon: Icons.trending_up,
              title: 'Strongest Subject',
              subtitle: _getSubjectName(bestSubject.key),
              value: '${(bestSubject.value.reduce((a, b) => a + b) / bestSubject.value.length).toStringAsFixed(1)}%',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _InsightTile(
              icon: Icons.trending_down,
              title: 'Needs Improvement',
              subtitle: _getSubjectName(worstSubject.key),
              value: '${(worstSubject.value.reduce((a, b) => a + b) / worstSubject.value.length).toStringAsFixed(1)}%',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _InsightTile(
              icon: Icons.schedule,
              title: 'Study Streak',
              subtitle: 'Keep up the momentum!',
              value: '${_records.length} days',
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateStats(List<double> values) {
    if (values.isEmpty) {
      return {
        'min': 0,
        'max': 0,
        'avg': 0,
      };
    }

    values.sort();
    return {
      'min': values.first,
      'max': values.last,
      'avg': values.reduce((a, b) => a + b) / values.length,
    };
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final double width;
  final Color color;

  const _StatCard({
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
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  final double height;

  const _ChartCard({
    required this.title,
    required this.chart,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: height,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.text, {
    required this.size,
    required this.borderColor,
  });

  final String text;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: size * 0.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color color;

  const _InsightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
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
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}