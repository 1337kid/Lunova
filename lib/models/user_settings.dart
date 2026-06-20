import 'package:hive/hive.dart';
part 'user_settings.g.dart';

@HiveType(typeId: 3)
class UserSettings {
  @HiveField(0)
  int defaultCycleLength;

  @HiveField(1)
  int periodLength;

  @HiveField(2)
  bool isFirstLaunch;

  @HiveField(3)
  DateTime? lastUpdated;

  UserSettings({
    this.defaultCycleLength = 28,
    this.periodLength = 5,
    this.isFirstLaunch = true,
    this.lastUpdated,
  });

  UserSettings copyWith({
    int? defaultCycleLength,
    int? periodLength,
    bool? isFirstLaunch,
    DateTime? lastUpdated,
  }) {
    return UserSettings(
      defaultCycleLength: defaultCycleLength ?? this.defaultCycleLength,
      periodLength: periodLength ?? this.periodLength,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
