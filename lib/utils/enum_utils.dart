import 'package:flutter/material.dart';
import '../models/cycle_entry.dart';

Color getPhaseColor(CyclePhase phase) {
  switch (phase) {
    case CyclePhase.menstrual:
      return Colors.red.shade400;
    case CyclePhase.follicular:
      return Colors.green.shade400;
    case CyclePhase.ovulatory:
      return Colors.orange.shade400;
    case CyclePhase.luteal:
      return Colors.purple.shade400;
  }
}

String getPhaseName(CyclePhase phase) {
  switch (phase) {
    case CyclePhase.menstrual:
      return 'Menstrual';
    case CyclePhase.follicular:
      return 'Follicular';
    case CyclePhase.ovulatory:
      return 'Ovulatory';
    case CyclePhase.luteal:
      return 'Luteal';
  }
}

String getFlowText(int intensity) {
  switch (intensity) {
    case 1:
      return 'Very Light';
    case 2:
      return 'Light';
    case 3:
      return 'Medium';
    case 4:
      return 'Heavy';
    case 5:
      return 'Very Heavy';
    default:
      return 'Unknown';
  }
}

String getSymptomName(Symptom symptom) {
  switch (symptom) {
    case Symptom.cramps:
      return 'Cramps';
    case Symptom.headache:
      return 'Headache';
    case Symptom.bloating:
      return 'Bloating';
    case Symptom.fatigue:
      return 'Fatigue';
    case Symptom.acne:
      return 'Acne';
    case Symptom.breastTenderness:
      return 'Breast Tenderness';
  }
}
