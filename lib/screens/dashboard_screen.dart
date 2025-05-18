
// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ivy_path/widgets/layout_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      drawer: !isDesktop ? const AppDrawer() : null,
      body: Row(
        children: [
          if (isDesktop) const AppDrawer(),
          if (isTablet && !isDesktop)
            const IvyNavRail(),
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
                        const WelcomeSection(),
                        const SizedBox(height: 32),
                        ProgressSummary(isWideScreen: isTablet),
                        const SizedBox(height: 32),
                        QuickActions(isWideScreen: isTablet),
                        const SizedBox(height: 32),
                        PremiumMaterials(isWideScreen: isTablet),
                        const SizedBox(height: 32),
                        const PerformanceChart(),
                        const SizedBox(height: 32),
                        const RecentNotifications(),
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



class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Daniel!',
          style: theme.textTheme.headlineLarge,
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 8),
        Text(
          'All set for today\'s learning?',
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

  const ProgressSummary({super.key, required this.isWideScreen});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _ProgressCard(
          title: 'Last Score',
          value: '85%',
          icon: Icons.grade,
          color: Colors.amber,
          width: isWideScreen ? 300 : double.infinity,
        ),
        _ProgressCard(
          title: 'Total Practice Time',
          value: '12.5 hrs',
          icon: Icons.timer,
          color: Colors.blue,
          width: isWideScreen ? 300 : double.infinity,
        ),
        _ProgressCard(
          title: 'Ongoing Test',
          value: 'Physics',
          icon: Icons.science,
          color: Colors.purple,
          width: isWideScreen ? 300 : double.infinity,
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  const _ProgressCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
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
              title: 'Practice Past Questions',
              icon: Icons.question_answer,
              onTap: () {},
              width: isWideScreen ? 300 : double.infinity,
            ),
            _ActionCard(
              title: 'Study Premium Materials',
              icon: Icons.book,
              onTap: () {},
              width: isWideScreen ? 300 : double.infinity,
            ),
            _ActionCard(
              title: 'View My Progress',
              icon: Icons.trending_up,
              onTap: () {},
              width: isWideScreen ? 300 : double.infinity,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final double width;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2, delay: 400.ms);
  }
}

class PremiumMaterials extends StatelessWidget {
  final bool isWideScreen;

  const PremiumMaterials({super.key, required this.isWideScreen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Materials',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MaterialCard(
              title: 'Advanced Physics Notes',
              subject: 'Physics',
              onTap: () {},
              width: isWideScreen ? 300 : double.infinity,
            ),
            _MaterialCard(
              title: 'Chemistry Formula Guide',
              subject: 'Chemistry',
              onTap: () {},
              width: isWideScreen ? 300 : double.infinity,
            ),
            _MaterialCard(
              title: 'Biology Diagrams',
              subject: 'Biology',
              onTap: () {},
              width: isWideScreen ? 300 : double.infinity,
            ),
          ],
        ),
      ],
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final String title;
  final String subject;
  final VoidCallback onTap;
  final double width;

  const _MaterialCard({
    required this.title,
    required this.subject,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                subject,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.visibility),
                label: const Text('View'),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.download),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, delay: 600.ms);
  }
}

class PerformanceChart extends StatelessWidget {
  const PerformanceChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                      if (value.toInt() < 0 || value.toInt() >= labels.length) {
                        return const Text('');
                      }
                      return Text(
                        labels[value.toInt()],
                        style: theme.textTheme.bodySmall,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 3),
                    FlSpot(1, 4),
                    FlSpot(2, 3.5),
                    FlSpot(3, 5),
                    FlSpot(4, 4),
                  ],
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
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
    ).animate().fadeIn().slideY(begin: 0.2, delay: 800.ms);
  }
}

class RecentNotifications extends StatelessWidget {
  const RecentNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Notifications',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.notifications,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  'New study materials available',
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  '2 hours ago',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: index == 0
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.2, delay: 1000.ms);
  }
}



