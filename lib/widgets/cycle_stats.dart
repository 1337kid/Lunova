import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/cycle_entry.dart';
import '../utils/date_utils.dart';

class CycleStats extends StatelessWidget {
  final DatabaseService databaseService;

  const CycleStats({required this.databaseService});

  @override
  Widget build(BuildContext context) {
    final entries = databaseService.getAllEntries();

    final lastPeriod = databaseService.getLastPeriodStart();
    final nextPrediction = databaseService.predictNextPeriod();
    final cycleDay = _getCurrentCycleDay(entries);

    return Container(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          _StatCard(
            title: "Cycle Day",
            value: cycleDay == null ? "?" : "$cycleDay",
            subtitle: cycleDay == null ? "Log period to start" : "of 28 days",
            icon: Icons.calendar_today,
            color: Colors.pink.shade100,
          ),
          _StatCard(
            title: "Last Period",
            value: lastPeriod == null ? "?" : formatDateShort(lastPeriod),
            subtitle: lastPeriod == null ? "No data yet" : daysAgo(lastPeriod),
            icon: Icons.history,
            color: Colors.purple.shade100,
          ),
          _StatCard(
            title: "Next Period",
            value: nextPrediction == null ? "?" : formatDateShort(nextPrediction),
            subtitle: nextPrediction == null ? "Log 1 period" : daysUntil(nextPrediction),
            icon: Icons.update,
            color: Colors.blue.shade100,
          ),
        ],
      )
    );
  }

  int? _getCurrentCycleDay(List<CycleEntry> entries) {
    final lastPeriod = databaseService.getLastPeriodStart(); 
    if (lastPeriod == null) return null;

    final daysSincePeriod = daysBetween(lastPeriod, DateTime.now());

    return (daysSincePeriod + 1) % 28;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16)
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey.shade700,),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  )
                )
              ],
            ),
            Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              )
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            )
          ],
        )
      )
    );
  }
}
