import 'package:hive/hive.dart';

part 'cycle_entry.g.dart';

@HiveType(typeId: 0)
class CycleEntry {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final CyclePhase phase;

  @HiveField(2)
  final List<Symptom> symptoms;

  @HiveField(3)
  final int? flowIntensity;

  @HiveField(4)
  final String? notes;

  @override
  String toString() {
    return "($date,$phase,$flowIntensity,$notes,${symptoms.toString()})";
  }

  CycleEntry({
    required this.date,
    required this.phase,
    this.symptoms = const [],
    this.flowIntensity,
    this.notes,
  });
}

@HiveType(typeId: 1)
enum CyclePhase {
  @HiveField(0)
  menstrual,
  @HiveField(1)
  follicular,
  @HiveField(2)
  ovulatory,
  @HiveField(3)
  luteal,
}

@HiveType(typeId: 2)
enum Symptom {
  @HiveField(0)
  cramps,
  @HiveField(1)
  headache,
  @HiveField(2)
  bloating,
  @HiveField(3)
  fatigue,
  @HiveField(4)
  acne,
  @HiveField(5)
  breastTenderness,
}
