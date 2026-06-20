import 'package:flutter/material.dart';
import 'package:lunova/utils/enum_utils.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';
import '../models/cycle_entry.dart';
import '../utils/analytics_helper.dart';
import '../utils/date_utils.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final analytics = AnalyticsHelper(appState.entries);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(Duration(microseconds: 500));
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header stats cards
              _buildStatsHeader(analytics),
              SizedBox(height: 24),

              // Cycle length chart
              _buildCycleLengthChart(analytics),
              SizedBox(height: 24),

              // Symptom frequency chart
              _buildSymptomChart(analytics),
              SizedBox(height: 24),

              // Tips based on data
              _buildTipsCard(analytics),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(AnalyticsHelper analytics) {
    final totalPeriods = analytics.getTotalPeriodsCount();
    final avgCycle = analytics.getAverageCycleLength();

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Periods',
            value: totalPeriods.toString(),
            icon: Icons.calendar_month,
            color: Colors.pink.shade900,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Avg Cycle',
            value: avgCycle != null ? '${avgCycle.round()} days' : '--',
            icon: Icons.calendar_month,
            color: Colors.pink.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildCycleLengthChart(AnalyticsHelper analytics) {
    final cycleLengths = analytics.getCycleLengths();

    if (cycleLengths.isEmpty) {
      return _buildEmptyChartCard(
        'Cycle Length History',
        'Log at least 2 periods to see your cycle pattern',
        Icons.show_chart,
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.pink.shade900),
                SizedBox(width: 8),
                Text(
                  'Cycle Length History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Days between period starts',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
            ),
            SizedBox(height: 8),

            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (cycleLengths.reduce((a, b) => a > b ? a : b) + 5)
                          .toDouble(),
                  barGroups: _getBarGroups(cycleLengths),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              '${value.toInt() + 1}',
                              style: TextStyle(fontSize: 11),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} days',
                          TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.pink.shade50,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getCycleSummary(analytics),
                      style: TextStyle(fontSize: 13),
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

  String _getCycleSummary(AnalyticsHelper analytics) {
    final avg = analytics.getAverageCycleLength();
    final shortest = analytics.getShortestCycle();
    final longest = analytics.getLongestCycle();

    if (avg == null) return 'Log more periods to see your cycle pattern';

    final variation = (longest! - shortest!);

    if (variation <= 3) {
      return 'Your cycle is very regular! Variation of only $variation days between cycles.';
    } else if (variation <= 7) {
      return 'Your cycle shows typical variation of $variation days. This is normal!';
    } else {
      return 'Your cycle varies by $variation days. Consider tracking other factors like stress or sleep.';
    }
  }

  List<BarChartGroupData> _getBarGroups(List<int> cycleLengths) {
    return cycleLengths.asMap().entries.map((entry) {
      final index = entry.key;
      final length = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: length.toDouble(),
            color: Colors.pink,
            width: 30,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildEmptyChartCard(String title, String message, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade600),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Symptom Freq Chart

  Widget _buildSymptomChart(AnalyticsHelper analytics) {
    final symptomFrequency = analytics.getSymptomFrequency();

    final frequentSymptoms =
        symptomFrequency.entries.where((entry) => entry.value > 0).toList();

    if (frequentSymptoms.isEmpty) {
      return _buildEmptyChartCard(
        'Symptom Tracking',
        'Log symptoms to see your patterns',
        Icons.pie_chart,
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.pink.shade900),
                SizedBox(width: 8),
                Text(
                  'Symptom Frequency',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: PieChart(
                    PieChartData(
                      sections: _getPieSections(frequentSymptoms),
                      centerSpaceRadius: 2,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        frequentSymptoms.map((entry) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getSymptomColor(
                                entry.key,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getSymptomColor(entry.key),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '${getSymptomName(entry.key)} (${entry.value})',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.shade900.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.shade700),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.pink.shade900),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getSymptomInsight(analytics),
                      style: TextStyle(fontSize: 13),
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

  String _getSymptomInsight(AnalyticsHelper analytics) {
    final mostCommon = analytics.getMostCommonSymptoms();
    if (mostCommon.isEmpty)
      return 'Log symptoms to see patterns and prepare for your cycle.';

    final symptomText = _getSymptomListText(mostCommon);
    return 'You most commonly experience $symptomText. Consider preparing remedies in advance.';
  }

  String _getSymptomListText(List<Symptom> symptoms) {
    if (symptoms.isEmpty) return '';
    if (symptoms.length == 1) return getSymptomName(symptoms[0]).toLowerCase();

    final last = symptoms.last;
    final others = symptoms.sublist(0, symptoms.length - 1);

    final othersText = others
        .map((s) => getSymptomName(s).toLowerCase())
        .join(', ');
    return '$othersText and ${getSymptomName(last).toLowerCase()}';
  }

  Color _getSymptomColor(Symptom symptom) {
    switch (symptom) {
      case Symptom.cramps:
        return Colors.red;
      case Symptom.headache:
        return Colors.orange;
      case Symptom.bloating:
        return Colors.green;
      case Symptom.fatigue:
        return Colors.blue;
      case Symptom.acne:
        return Colors.purple;
      case Symptom.breastTenderness:
        return Colors.pink;
    }
  }

  List<PieChartSectionData> _getPieSections(
    List<MapEntry<Symptom, int>> symptoms,
  ) {
    final total = symptoms.fold(0, (sum, entry) => sum + entry.value);

    return symptoms.asMap().entries.map((entry) {
      final index = entry.key;
      final symptom = entry.value;
      final count = entry.value.value;
      final percentage = (count / total) * 100;

      return PieChartSectionData(
        color: _getSymptomColor(symptom.key),
        value: count.toDouble(),
        title: '${percentage.round()}%',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Tips based on data

  Widget _buildTipsCard(AnalyticsHelper analytics) {
    final mostCommonSymptoms = analytics.getMostCommonSymptoms();
    final avgCycle = analytics.getAverageCycleLength();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.pink.shade900),
                SizedBox(width: 8),
                Text(
                  'Personalized Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            SizedBox(height: 20),

            if (avgCycle != null)
              _buildTipItem(
                icon: Icons.timeline,
                title: 'Cycle Regularity',
                description:
                    avgCycle > 35
                        ? 'Your cycle is longer than average (${avgCycle.round()} days). This is normal for many people.'
                        : avgCycle < 21
                        ? 'Your cycle is shorter than average (${avgCycle.round()} days). Consider tracking patterns.'
                        : 'Your average cycle is ${avgCycle.round()} days, which falls within the typical 21-35 day range.',
              ),

            SizedBox(height: 12),

            if (mostCommonSymptoms.isNotEmpty)
              _buildTipItem(
                icon: Icons.favorite,
                title: 'Common Symptoms',
                description:
                    'You frequently experience ${_getSymptomListText(mostCommonSymptoms)}. Tracking these can help you prepare.',
              ),

            SizedBox(height: 12),

            // Tip 3: Tracking consistency
            _buildTipItem(
              icon: Icons.analytics,
              title: 'Tracking Consistency',
              description:
                  analytics.getTotalPeriodsCount() < 3
                      ? 'Keep logging! More data means better predictions and insights.'
                      : 'Great consistency! With ${analytics.getTotalPeriodsCount()} periods logged, your predictions are getting more accurate.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.pink.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.pink.shade300),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade300),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}
