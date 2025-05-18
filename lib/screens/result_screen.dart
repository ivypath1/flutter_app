import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ResultPage extends StatefulWidget {
  final bool isPracticeMode;
  final Map<String, dynamic> userData;
  final List<SubjectResult> subjectResults;

  const ResultPage({
    super.key,
    required this.isPracticeMode,
    required this.userData,
    required this.subjectResults,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPracticeMode ? 'Practice Results' : 'Mock UTME Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printResult(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadResult(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.isPracticeMode) _buildUserInfoSection(theme),
                const SizedBox(height: 24),
                widget.isPracticeMode
                    ? _buildPracticeModeContent(theme)
                    : _buildMockUTMEModeContent(theme),
                const SizedBox(height: 24),
                // _buildWatermarkSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Examination Result Slip', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildInfoRow('Name:', widget.userData['name']),
            _buildInfoRow('Exam No:', widget.userData['examNumber']),
            _buildInfoRow('Admission Type:', widget.userData['admissionType']),
            _buildInfoRow('State/LGA:', '${widget.userData['state']}/${widget.userData['lga']}'),
            _buildInfoRow('Phone:', widget.userData['phone']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildPracticeModeContent(ThemeData theme) {
    final totalScore = widget.subjectResults.fold(0, (sum, item) => (sum + item.score).toInt()) / widget.subjectResults.length;
    final totalTime = widget.subjectResults.fold(0, (sum, item) => (sum + item.timeSpent).toInt());

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Performance Summary', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryChip('Total Score', '${totalScore.toStringAsFixed(1)}%'),
                    _buildSummaryChip('Total Time', '${totalTime.toStringAsFixed(1)} mins'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Score Distribution by Subject', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 60,
                      sections: _buildScoreSections(theme),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegend(theme),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Time Spent per Subject', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: theme.colorScheme.surfaceVariant,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final subject = widget.subjectResults[groupIndex].subject;
                            return BarTooltipItem(
                              '$subject\n${rod.toY} mins',
                              TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < widget.subjectResults.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    widget.subjectResults[index].subject.substring(0, 3),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: widget.subjectResults.asMap().entries.map((entry) {
                        final index = entry.key;
                        final result = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: result.timeSpent,
                              color: _getChartColor(index),
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                      gridData: const FlGridData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Detailed Results', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Subject')),
              DataColumn(label: Text('Score %')),
              DataColumn(label: Text('Time Spent (mins)')),
            ],
            rows: widget.subjectResults.map((result) {
              return DataRow(cells: [
                DataCell(Text(result.subject)),
                DataCell(Text('${result.score.toStringAsFixed(1)}')),
                DataCell(Text('${result.timeSpent.toStringAsFixed(1)}')),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildScoreSections(ThemeData theme) {
    return widget.subjectResults.asMap().entries.map((entry) {
      final index = entry.key;
      final result = entry.value;
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 14.0 : 12.0;
      final radius = isTouched ? 70.0 : 60.0;

      return PieChartSectionData(
        color: _getChartColor(index),
        value: result.score,
        title: '${result.score.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _touchedIndex == index
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  result.subject.substring(0, 3),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 10,
                  ),
                ),
              )
            : null,
      );
    }).toList();
  }

  Widget _buildLegend(ThemeData theme) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: widget.subjectResults.asMap().entries.map((entry) {
        final index = entry.key;
        final result = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              color: _getChartColor(index),
            ),
            const SizedBox(width: 4),
            Text(
              result.subject,
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getChartColor(int index) {
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.amber.shade400,
      Colors.indigo.shade400,
    ];
    return colors[index % colors.length];
  }

  Widget _buildMockUTMEModeContent(ThemeData theme) {
    final utmeTotal = widget.subjectResults.fold(0, (sum, item) => sum + (item.utmeScore ?? 0));
    final olevelTotal = widget.subjectResults.fold(0, (sum, item) => sum + (item.olevelScore ?? 0));
    final postUtmeTotal = widget.subjectResults.fold(0, (sum, item) => sum + (item.postUtmeScore ?? 0));

    final postUtmeScreeningScore = (olevelTotal + postUtmeTotal) / 50;
    final utmeScore = utmeTotal / 400 * 50;
    final aggregateScore = postUtmeScreeningScore + utmeScore;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Subject Scores', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Subject')),
                      DataColumn(label: Text('UTME (400)')),
                      DataColumn(label: Text("O'Level Grade")),
                      DataColumn(label: Text("O'Level (10)")),
                      DataColumn(label: Text('Post-UTME (40)')),
                    ],
                    rows: widget.subjectResults.map((result) {
                      return DataRow(cells: [
                        DataCell(Text(result.subject)),
                        DataCell(Text((result.utmeScore ?? 0).toString())),
                        DataCell(Text(result.olevelGrade ?? 'N/A')),
                        DataCell(Text((result.olevelScore ?? 0).toString())),
                        DataCell(Text((result.score ?? 0).toString())),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Score Calculation', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildScoreRow('Post-UTME Screening Score', '($olevelTotal + $postUtmeTotal) / 50', postUtmeScreeningScore.toStringAsFixed(2)),
                _buildScoreRow('UTME Score', '$utmeTotal / 400 * 50', utmeScore.toStringAsFixed(2)),
                const Divider(),
                _buildScoreRow('Aggregate Score', 'Post-UTME + UTME Score', aggregateScore.toStringAsFixed(2), isTotal: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(String label, String calculation, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              )),
              Text(calculation, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Text(value, style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 16,
          )),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Text(label[0], style: const TextStyle(fontWeight: FontWeight.bold))),
      label: Text('$label: $value'),
    );
  }

  Widget _buildWatermarkSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0.1,
          child: Image.network('assets/university_logo.png', height: 200),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Image.asset('assets/qr_code.png'),
          ),
        ),
      ],
    );
  }

  void _printResult() {
    // Implement print functionality
  }

  void _downloadResult() {
    // Implement download functionality
  }
}

class SubjectResult {
  final String subject;
  final double score;
  final double timeSpent;
  final int? utmeScore;
  final String? olevelGrade;
  final int? olevelScore;
  final int? postUtmeScore;

  SubjectResult({
    required this.subject,
    required this.score,
    required this.timeSpent,
    this.utmeScore,
    this.olevelGrade,
    this.olevelScore,
    this.postUtmeScore,
  });
}