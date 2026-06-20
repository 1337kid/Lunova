// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleEntryAdapter extends TypeAdapter<CycleEntry> {
  @override
  final int typeId = 0;

  @override
  CycleEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleEntry(
      date: fields[0] as DateTime,
      phase: fields[1] as CyclePhase,
      symptoms: (fields[2] as List).cast<Symptom>(),
      flowIntensity: fields[3] as int?,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CycleEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.phase)
      ..writeByte(2)
      ..write(obj.symptoms)
      ..writeByte(3)
      ..write(obj.flowIntensity)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CyclePhaseAdapter extends TypeAdapter<CyclePhase> {
  @override
  final int typeId = 1;

  @override
  CyclePhase read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CyclePhase.menstrual;
      case 1:
        return CyclePhase.follicular;
      case 2:
        return CyclePhase.ovulatory;
      case 3:
        return CyclePhase.luteal;
      default:
        return CyclePhase.menstrual;
    }
  }

  @override
  void write(BinaryWriter writer, CyclePhase obj) {
    switch (obj) {
      case CyclePhase.menstrual:
        writer.writeByte(0);
        break;
      case CyclePhase.follicular:
        writer.writeByte(1);
        break;
      case CyclePhase.ovulatory:
        writer.writeByte(2);
        break;
      case CyclePhase.luteal:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CyclePhaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SymptomAdapter extends TypeAdapter<Symptom> {
  @override
  final int typeId = 2;

  @override
  Symptom read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Symptom.cramps;
      case 1:
        return Symptom.headache;
      case 2:
        return Symptom.bloating;
      case 3:
        return Symptom.fatigue;
      case 4:
        return Symptom.acne;
      case 5:
        return Symptom.breastTenderness;
      default:
        return Symptom.cramps;
    }
  }

  @override
  void write(BinaryWriter writer, Symptom obj) {
    switch (obj) {
      case Symptom.cramps:
        writer.writeByte(0);
        break;
      case Symptom.headache:
        writer.writeByte(1);
        break;
      case Symptom.bloating:
        writer.writeByte(2);
        break;
      case Symptom.fatigue:
        writer.writeByte(3);
        break;
      case Symptom.acne:
        writer.writeByte(4);
        break;
      case Symptom.breastTenderness:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
