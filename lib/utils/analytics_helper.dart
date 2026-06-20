import '../models/cycle_entry.dart';

class AnalyticsHelper {
  final List<CycleEntry> entries;

  AnalyticsHelper(this.entries);

  List<CycleEntry> getPeriodStarts() {
    if (entries.isEmpty) return [];

    final sorted = List<CycleEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<CycleEntry> starts = [];

    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].phase == CyclePhase.menstrual) {
        if (i == 0 ||
            sorted[i].date.difference(sorted[i - 1].date).inDays > 3) {
          starts.add(sorted[i]);
        }
      }
    }
    return starts;
  }

  List<int> getCycleLengths() {
    final periods = getPeriodStarts();
    final List<int> lengths = [];

    for (int i = 0; i < periods.length - 1; i++) {
      final currentPeriod = periods[i];
      final nextPeriod = periods[i + 1];

      final cycelLength = nextPeriod.date.difference(currentPeriod.date).inDays;
      lengths.add(cycelLength);
    }
    return lengths;
  }

  double? getAverageCycleLength() {
    final lengths = getCycleLengths();
    if (lengths.isEmpty) return null;

    final sum = lengths.reduce((a, b) => a + b);
    return sum / lengths.length;
  }

  int? getShortestCycle() {
    final lengths = getCycleLengths();
    if (lengths.isEmpty) return null;
    return lengths.reduce((a, b) => a < b ? a : b);
  }

  int? getLongestCycle() {
    final lengths = getCycleLengths();
    if (lengths.isEmpty) return null;
    return lengths.reduce((a, b) => a > b ? a : b);
  }

  Map<Symptom, int> getSymptomFrequency() {
    final Map<Symptom, int> frequency = {};

    for (var symptom in Symptom.values) {
      frequency[symptom] = 0;
    }

    for (var entry in entries) {
      for (var symptom in entry.symptoms) {
        frequency[symptom] = (frequency[symptom] ?? 0) + 1;
      }
    }

    return frequency;
  }

  int getTotalPeriodsCount() {
    return getPeriodStarts().length;
  }

  List<Symptom> getMostCommonSymptoms() {
    final frequency = getSymptomFrequency();
    if (frequency.isEmpty) return [];

    final maxCount = frequency.values.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return [];

    return frequency.entries
        .where((entry) => entry.value == maxCount)
        .map((entry) => entry.key)
        .toList();
  }

  DateTime? getPredictedNextPeriod() {
    final periods = getPeriodStarts();
    if (periods.isEmpty) return null;

    final lastPeriod = periods.last.date;
    final avgLength = getAverageCycleLength();

    if (avgLength == null) return null;

    return lastPeriod.add(Duration(days: avgLength.round()));
  }

  int? getDaysUntilNextPeriod() {
    final nextPeriod = getPredictedNextPeriod();
    if (nextPeriod == null) return null;

    final today = DateTime.now();
    final days = nextPeriod.difference(today).inDays;

    return days < 0 ? null : days;
  }
}
