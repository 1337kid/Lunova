import 'package:hive_flutter/hive_flutter.dart';
import '../models/cycle_entry.dart';
import '../models/user_settings.dart';
import 'notification_service.dart';

class DatabaseService {
  late Box<CycleEntry> _box;
  late Box<UserSettings> _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(CycleEntryAdapter());
    Hive.registerAdapter(CyclePhaseAdapter());
    Hive.registerAdapter(SymptomAdapter());
    Hive.registerAdapter(UserSettingsAdapter());

    _box = await Hive.openBox<CycleEntry>('cycle_entries');
    _settingsBox = await Hive.openBox<UserSettings>('user_settings');

    if (!_settingsBox.containsKey('settings')) {
      await _settingsBox.put('settings', UserSettings());
    }
  }

  Future<void> addEntry(CycleEntry entry) async {
    await _box.put(entry.date.toIso8601String(), entry);
  }

  List<CycleEntry> getAllEntries() {
    return _box.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  CycleEntry? getEntryByDate(DateTime date) {
    return _box.get(date.toIso8601String());
  }

  Future<void> updateEntry(DateTime date, CycleEntry entry) async {
    await _box.put(date.toIso8601String(), entry);
  }

  Future<void> deleteEntry(DateTime date) async {
    await _box.delete(date.toIso8601String());
  }

  List<DateTime> getActualPeriodStarts() {
    final bleedingDates =
        getAllEntries()
            .where((e) => e.phase == CyclePhase.menstrual)
            .map((e) => e.date)
            .toList()
          ..sort();

    if (bleedingDates.isEmpty) return [];

    final periodStarts = <DateTime>[];
    DateTime? previousBleedingDate;

    for (final date in bleedingDates) {
      final startsNewPeriod =
          previousBleedingDate == null ||
          date.difference(previousBleedingDate).inDays > 3;

      if (startsNewPeriod) {
        periodStarts.add(date);
      }
      previousBleedingDate = date;
    }
    return periodStarts;
  }

  DateTime? getLastPeriodStart() {
    final starts = getActualPeriodStarts();
    return starts.isNotEmpty ? starts.last : null;
  }

  List<int> getActualCycleLengths() {
    final periodStarts = getActualPeriodStarts();
    final cycleLengths = <int>[];

    for (var i = 1; i < periodStarts.length; i++) {
      cycleLengths.add(periodStarts[i].difference(periodStarts[i - 1]).inDays);
    }
    return cycleLengths;
  }

  List<CycleEntry> getPeriodStarts() {
    return getAllEntries()
        .where((entry) => entry.phase == CyclePhase.menstrual)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  int getEffectiveCycleLength() {
    final actualLengths = getActualCycleLengths();
    if (actualLengths.isNotEmpty) {
      final lastThree = actualLengths.reversed.take(3).toList();
      final sum = lastThree.reduce((a, b) => a + b);
      return (sum / lastThree.length).round();
    }
    return getSettings().defaultCycleLength;
  }

  DateTime? predictNextPeriod() {
    final lastPeriod = getLastPeriodStart();
    if (lastPeriod == null) return null;

    final cycleLength = getEffectiveCycleLength();
    return lastPeriod.add(Duration(days: cycleLength));
  }

  List<DateTime> getFertileWindow({DateTime? cycleStartDate}) {
    final startDate = cycleStartDate ?? getLastPeriodStart();
    if (startDate == null) return [];

    final cycleLength = getEffectiveCycleLength();
    final ovulationDay = cycleLength - 14;

    final fertileStart = startDate.add(Duration(days: ovulationDay - 5));
    final fertileEnd = startDate.add(Duration(days: ovulationDay + 1));

    final List<DateTime> fertileDays = [];
    final duration = fertileEnd.difference(fertileStart).inDays;

    for (int i = 0; i <= duration; i++) {
      fertileDays.add(fertileStart.add(Duration(days: i)));
    }
    return fertileDays;
  }

  List<DateTime> getPeriodDays({DateTime? cycleStartDate}) {
    final startDate = cycleStartDate ?? predictNextPeriod();
    if (startDate == null) return [];

    final periodLength = getSettings().periodLength;

    final List<DateTime> periodDays = [];
    for (int i = 0; i < periodLength; i++) {
      periodDays.add(startDate.add(Duration(days: i)));
    }
    return periodDays;
  }

  double getCycleProgress() {
    final lastPeriod = getLastPeriodStart();
    if (lastPeriod == null) return 0.0;

    final today = DateTime.now();
    final daysSincePeriod = today.difference(lastPeriod).inDays;
    final cycleLength = getEffectiveCycleLength();

    if (daysSincePeriod < 0) return 0.0;
    if (daysSincePeriod >= cycleLength) return 1.0;
    return daysSincePeriod / cycleLength;
  }

  CyclePhase getCurrentPhase() {
    return getCurrentPhaseForDate(DateTime.now());
  }

  CyclePhase getCurrentPhaseForDate(DateTime date) {
    final lastPeriod = getLastPeriodStart();
    if (lastPeriod == null) return CyclePhase.follicular;

    final cycleLength = getEffectiveCycleLength();
    final periodLength = getSettings().periodLength;

    int daysDiff = date.difference(lastPeriod).inDays;
    DateTime currentCycleStart = lastPeriod;

    if (daysDiff >= 0) {
      int cyclesPassed = daysDiff ~/ cycleLength;
      currentCycleStart = lastPeriod.add(
        Duration(days: cyclesPassed * cycleLength),
      );
    } else {
      int cyclesBack = (-daysDiff / cycleLength).ceil();
      currentCycleStart = lastPeriod.subtract(
        Duration(days: cyclesBack * cycleLength),
      );
    }

    final daysSincePeriod = date.difference(currentCycleStart).inDays;
    final ovulationDay = cycleLength - 14;

    if (daysSincePeriod < periodLength) {
      return CyclePhase.menstrual;
    } else if (daysSincePeriod < ovulationDay - 5) {
      return CyclePhase.follicular;
    } else if (daysSincePeriod <= ovulationDay + 1) {
      return CyclePhase.ovulatory;
    } else {
      return CyclePhase.luteal;
    }
  }

  DateTime? getOvulationDay({DateTime? cycleStartDate}) {
    final startDate = cycleStartDate ?? getLastPeriodStart();
    if (startDate == null) return null;

    final cycleLength = getEffectiveCycleLength();
    final ovulationDayOffset = cycleLength - 14;

    return startDate.add(Duration(days: ovulationDayOffset));
  }

  Map<int, List<DateTime>> getFuturePeriodDays({int numberOfCycles = 12}) {
    final lastPeriod = getLastPeriodStart();
    if (lastPeriod == null) return {};

    final Map<int, List<DateTime>> futurePeriods = {};
    final periodLength = getSettings().periodLength;
    final cycleLength = getEffectiveCycleLength();

    DateTime currentCycleStart = lastPeriod;

    for (int cycle = 0; cycle < numberOfCycles; cycle++) {
      final nextPeriodStart = currentCycleStart.add(
        Duration(days: cycleLength),
      );
      final List<DateTime> periodDays = [];

      for (int i = 0; i < periodLength; i++) {
        periodDays.add(nextPeriodStart.add(Duration(days: i)));
      }

      futurePeriods[cycle] = periodDays;
      currentCycleStart = nextPeriodStart;
    }

    return futurePeriods;
  }

  Map<int, List<DateTime>> getFutureFertileWindows({int numberOfCycles = 12}) {
    final lastPeriod = getLastPeriodStart();
    if (lastPeriod == null) return {};

    final Map<int, List<DateTime>> futureFertileWindows = {};
    final cycleLength = getEffectiveCycleLength();

    DateTime currentCycleStart = lastPeriod;

    for (int cycle = 0; cycle < numberOfCycles; cycle++) {
      final nextCycleStart = currentCycleStart.add(Duration(days: cycleLength));
      final fertileWindow = getFertileWindow(cycleStartDate: nextCycleStart);

      futureFertileWindows[cycle] = fertileWindow;
      currentCycleStart = nextCycleStart;
    }

    return futureFertileWindows;
  }

  Map<int, DateTime> getFutureOvulationDays({int numberOfCycles = 12}) {
    final lastPeriod = getLastPeriodStart();
    if (lastPeriod == null) return {};

    final Map<int, DateTime> futureOvulations = {};
    final cycleLength = getEffectiveCycleLength();

    DateTime currentCycleStart = lastPeriod;

    for (int cycle = 0; cycle < numberOfCycles; cycle++) {
      final nextCycleStart = currentCycleStart.add(Duration(days: cycleLength));
      final ovulationDay = getOvulationDay(cycleStartDate: nextCycleStart);

      if (ovulationDay != null) {
        futureOvulations[cycle] = ovulationDay;
      }

      currentCycleStart = nextCycleStart;
    }

    return futureOvulations;
  }

  UserSettings getSettings() {
    return _settingsBox.get('settings', defaultValue: UserSettings())!;
  }

  Future<void> saveSettings(UserSettings settings) async {
    try {
      await _settingsBox.put('settings', settings);
      print('Settings saved successfully!');
    } catch (e) {
      print('Error saving settings: $e');
      rethrow;
    }
  }

  bool isFirstLaunch() {
    return getSettings().isFirstLaunch;
  }

  Future<void> markFirstLaunchComplete() async {
    final settings = getSettings();
    settings.isFirstLaunch = false;
    settings.lastUpdated = DateTime.now();
    await _settingsBox.put('settings', settings);
  }
}
