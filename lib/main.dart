import 'package:flutter/material.dart';
import 'package:lunova/models/cycle_entry.dart';
import 'package:lunova/models/user_settings.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseService = DatabaseService();
  await databaseService.init();

  runApp(MyApp(databaseService: databaseService));
}

class MyApp extends StatelessWidget {
  final DatabaseService databaseService;

  const MyApp({required this.databaseService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(databaseService),
      child: MaterialApp(
        title: 'Lunova',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.pink,
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.pink,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        home: Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.settings.isFirstLaunch) {
              return OnboardingScreen();
            }
            return MainScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  final DatabaseService db;
  UserSettings _settings = UserSettings();
  UserSettings get settings => _settings;

  List<CycleEntry> entries = [];

  AppState(this.db) {
    _init();
  }

  Future<void> _init() async {
    loadEntries();
    loadSettings();
    await _scheduleNotifications();
  }

  Future<void> loadEntries() async {
    try {
      entries = db.getAllEntries();
      print('Loaded ${entries.length} entries');
      notifyListeners();

      await _scheduleNotifications();
    } catch (e) {
      print('Error loading entries: $e');
    }
  }

  Future<void> addEntry(CycleEntry entry) async {
    try {
      await db.addEntry(entry);
      await loadEntries();
      print('Added entry for ${entry.date}');

      await _scheduleNotifications();
    } catch (e) {
      print('Error adding entry: $e');
      rethrow;
    }
  }

  Future<void> deleteEntry(DateTime date) async {
    try {
      await db.deleteEntry(date);
      await loadEntries();
      print('Deleted entry for $date');

      await _scheduleNotifications();
    } catch (e) {
      print('Error deleting entry: $e');
      rethrow;
    }
  }

  // Settings

  Future<void> loadSettings() async {
    _settings = db.getSettings();
    notifyListeners();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    try {
      await db.saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
      await loadEntries();

      await _scheduleNotifications();
    } catch (e) {
      print('Error updating settings: $e');
      rethrow;
    }
  }

  Future<void> _scheduleNotifications() async {
    try {
      await notificationService.init();

      await notificationService.scheduleAllNotifications(db);
      print('Notifications scheduled successfully');
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }
}
