import 'package:flutter/material.dart';
import '../models/cycle_entry.dart';
import '../utils/enum_utils.dart';

class SymptomSelector extends StatefulWidget {
  final Function(List<Symptom>) onSymptomsChanged;

  final List<Symptom> initialSymptoms;

  const SymptomSelector({
    required this.onSymptomsChanged,
    this.initialSymptoms = const [],
    Key? key,
  }) : super(key: key);

  @override
  State<SymptomSelector> createState() => _SymptomSelectorState();
}

class _SymptomSelectorState extends State<SymptomSelector> {
  late Map<Symptom, bool> _selectedSymptoms;

  @override
  void initState() {
    super.initState();

    _selectedSymptoms = {};

    for (var symptom in Symptom.values) {
      _selectedSymptoms[symptom] = false;
    }

    for (var symptom in widget.initialSymptoms) {
      _selectedSymptoms[symptom] = true;
    }
  }

  List<Symptom> _getSelectedSymptoms() {
    return _selectedSymptoms.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  void _onSystemToggled(Symptom symptom, bool? isSelected) {
    setState(() {
      _selectedSymptoms[symptom] = isSelected ?? false;
    });

    widget.onSymptomsChanged(_getSelectedSymptoms());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Symptoms",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 12),

        GridView.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 2.5,
          ),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: Symptom.values.length,
          itemBuilder: (context, index) {
            final symptom = Symptom.values[index];
            final isSelected = _selectedSymptoms[symptom] ?? false;

            return CheckboxListTile(
              title: Text(getSymptomName(symptom)),
              value: isSelected,
              onChanged: (bool? value) => _onSystemToggled(symptom, value),
              activeColor: Colors.pink,
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          },
        ),
      ],
    );
  }
}
