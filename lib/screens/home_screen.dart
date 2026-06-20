import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../main.dart';
import '../models/cycle_entry.dart';
import '../widgets/cycle_stats.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/enum_utils.dart';
import '../widgets/add_entry_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();

  DateTime _selectedDay = DateTime.now();

  Map<DateTime, CycleEntry> _periodEntries = {};

  Map<DateTime, bool> _fertileDays = {};
  Map<DateTime, bool> _periodDays = {};
  Map<DateTime, bool> _ovulationDays = {};

  @override
  void initState() {
    super.initState();

    _loadPeriodEntries();
    _loadCycleMarkers();
  }

  void _loadPeriodEntries() {
    final appState = Provider.of<AppState>(context, listen: false);

    final Map<DateTime, CycleEntry> newMap = {};

    for (var entry in appState.entries) {
      if (entry.phase == CyclePhase.menstrual) {
        final dataKey = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        newMap[dataKey] = entry;
      }
    }

    _periodEntries = newMap;
  }

  void _loadCycleMarkers() {
    final appState = Provider.of<AppState>(context, listen: false);
    final db = appState.db;

    final Map<DateTime, bool> newFertileDays = {};
    final Map<DateTime, bool> newPeriodDays = {};
    final Map<DateTime, bool> newOvulationDays = {};

    final lastPeriod = db.getLastPeriodStart();
    if (lastPeriod != null) {
      final currentPeriodDays = db.getPeriodDays(cycleStartDate: lastPeriod);
      for (var date in currentPeriodDays) {
        final normalized = DateTime(date.year, date.month, date.day);
        newPeriodDays[normalized] = true;
      }

      final fertileWindow = db.getFertileWindow(cycleStartDate: lastPeriod);
      for (var date in fertileWindow) {
        final normalized = DateTime(date.year, date.month, date.day);
        newFertileDays[normalized] = true;
      }

      final ovulationDay = db.getOvulationDay(cycleStartDate: lastPeriod);
      if (ovulationDay != null) {
        final normalized = DateTime(
          ovulationDay.year,
          ovulationDay.month,
          ovulationDay.day,
        );
        newOvulationDays[normalized] = true;
      }

      const int futureCycles = 12;

      final futurePeriods = db.getFuturePeriodDays(
        numberOfCycles: futureCycles,
      );
      for (var periodDays in futurePeriods.values) {
        for (var date in periodDays) {
          final normalized = DateTime(date.year, date.month, date.day);
          newPeriodDays[normalized] = true;
        }
      }

      final futureFertileWindows = db.getFutureFertileWindows(
        numberOfCycles: futureCycles,
      );
      for (var fertileDays in futureFertileWindows.values) {
        for (var date in fertileDays) {
          final normalized = DateTime(date.year, date.month, date.day);
          newFertileDays[normalized] = true;
        }
      }

      final futureOvulations = db.getFutureOvulationDays(
        numberOfCycles: futureCycles,
      );
      for (var date in futureOvulations.values) {
        final normalized = DateTime(date.year, date.month, date.day);
        newOvulationDays[normalized] = true;
      }
    }

    setState(() {
      _fertileDays = newFertileDays;
      _periodDays = newPeriodDays;
      _ovulationDays = newOvulationDays;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CycleStats(databaseService: appState.db),

            SizedBox(height: 16),

            _buildCalendar(),
            SizedBox(height: 8),

            _buildSelectedDateInfo(),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _loadPeriodEntries();
    _loadCycleMarkers();
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: _focusedDay,

        selectedDayPredicate: (day) {
          return date_utils.isSameDay(_selectedDay, day);
        },

        calendarStyle: const CalendarStyle(outsideDaysVisible: false),

        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, date, _) => _buildCalendarCell(date),
          todayBuilder: (context, date, _) => _buildCalendarCell(date),
          selectedBuilder: (context, date, _) => _buildCalendarCell(date),
        ),

        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
      ),
    );
  }

  Widget _buildCalendarCell(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isToday = date_utils.isToday(date);
    final isSelected = date_utils.isSameDay(_selectedDay, date);

    BoxDecoration? decoration;
    Border? cellBorder;
    Color textColor = Colors.white;

    final hasLoggedPeriod = _periodEntries.containsKey(normalizedDate);
    final isPredictedPeriod = _periodDays.containsKey(normalizedDate);
    final isFertile = _fertileDays.containsKey(normalizedDate);
    final isOvulation = _ovulationDays.containsKey(normalizedDate);

    if (isSelected) {
      cellBorder = Border.all(color: Colors.pinkAccent.shade100, width: 2);
    } else if (isPredictedPeriod && !hasLoggedPeriod) {
      cellBorder = Border.all(color: Colors.red.shade400, width: 2);
    } else if (isToday) {
      cellBorder = Border.all(color: Colors.grey.shade400, width: 1);
    }

    if (hasLoggedPeriod) {
      decoration = BoxDecoration(
        color: Colors.red.shade400,
        shape: BoxShape.circle,
        border:
            cellBorder ??
            (isPredictedPeriod
                ? Border.all(color: Colors.red.shade600, width: 1)
                : null),
      );
    } else if (isOvulation) {
      decoration = BoxDecoration(
        color: Colors.blue.shade800,
        shape: BoxShape.circle,
        border: cellBorder,
      );
    } else if (isFertile && !isOvulation) {
      decoration = BoxDecoration(
        color: Colors.blue.shade300,
        shape: BoxShape.circle,
        border: cellBorder,
      );
    } else {
      decoration = BoxDecoration(
        color:
            (isToday && !isSelected)
                ? Colors.pink.shade700
                : Colors.transparent,
        shape: BoxShape.circle,
        border: cellBorder,
      );
    }

    if (!hasLoggedPeriod &&
        !isPredictedPeriod &&
        !isFertile &&
        !isSelected &&
        !isToday) {
      textColor = Colors.white70;
    }

    return Container(
      margin: const EdgeInsets.all(5),
      decoration: decoration,
      child: Center(
        child: Text(
          date.day.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMarker(Color color, double size) {
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSelectedDateInfo() {
    final appState = Provider.of<AppState>(context);
    final db = appState.db;

    final normalizedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    final entry = _periodEntries[normalizedDate];

    final lastPeriod = db.getLastPeriodStart();
    String cyclePhase = '';
    String cycleDayText = '';

    if (lastPeriod != null) {
      final daysSincePeriod = _selectedDay.difference(lastPeriod).inDays;
      if (daysSincePeriod >= 0) {
        cycleDayText = 'Day ${daysSincePeriod + 1}';

        final currentPhase = db.getCurrentPhaseForDate(_selectedDay);
        cyclePhase = getPhaseName(currentPhase);
      }
    }

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: Colors.pink),
              SizedBox(width: 8),
              Text(
                date_utils.formatDateLong(_selectedDay),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (date_utils.isToday(_selectedDay))
                Container(
                  margin: EdgeInsets.only(left: 8),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),

          // Check for fertile window
          if (_fertileDays.containsKey(normalizedDate))
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.lightBlue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fertile Window - High chance of conception',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.lightBlue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (entry != null)
            _buildEntryDetails(entry)
          else
            _buildNoEntryPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildEntryDetails(CycleEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: getPhaseColor(entry.phase),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            getPhaseName(entry.phase),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: 8),

        if (entry.flowIntensity != null)
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.water_drop, size: 16, color: Colors.red.shade300),
                SizedBox(width: 8),
                Text('Flow: ${getFlowText(entry.flowIntensity!)}'),
              ],
            ),
          ),

        if (entry.symptoms.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              children:
                  entry.symptoms.map((symptom) {
                    return Chip(
                      label: Text(getSymptomName(symptom)),
                      backgroundColor: Theme.of(context).cardColor,
                      avatar: Icon(
                        Icons.favorite,
                        size: 16,
                        color: Colors.pink,
                      ),
                    );
                  }).toList(),
            ),
          ),

        if (entry.notes != null && entry.notes!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notes_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Notes",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text('${entry.notes}'),
              ],
            ),
          ),

        SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: () => _confirmDelete(entry.date),
          icon: Icon(Icons.delete, size: 18),
          label: Text('Delete Entry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade100,
            foregroundColor: Colors.red.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildNoEntryPlaceholder() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(
                Icons.circle_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 12),
              Text(
                'No entry for this day',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed:
                    () => _showAddEntryDialog(
                      context,
                      preselectedDate: _selectedDay,
                    ),
                label: Text('Add Entry'),
                icon: Icon(Icons.add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddEntryDialog(BuildContext context, {DateTime? preselectedDate}) {
    showDialog(
      context: context,
      builder: (context) => AddEntryDialog(initialDate: preselectedDate),
    );
  }

  void _confirmDelete(date) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Entry'),
            content: Text(
              'Are you sure you want to delete the entry for ${date_utils.formatDateShort(date)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  await appState.deleteEntry(date);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade400,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Entry deleted successfully',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColorDark.withValues(alpha: 0.95),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.all(8),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                    ),
                  );
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
