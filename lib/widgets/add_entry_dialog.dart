import 'package:flutter/material.dart';
import 'package:lunova/utils/enum_utils.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/cycle_entry.dart';
import '../utils/date_utils.dart';
import 'symptom_selector.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class AddEntryDialog extends StatelessWidget {
  final DateTime? initialDate;
  final CycleEntry? existingEntry;

  const AddEntryDialog({this.initialDate, this.existingEntry, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
      child: _addEntryDialogContent(
        initialDate: initialDate,
        existingEntry: existingEntry,
      ),
    );
  }
}

class _addEntryDialogContent extends StatefulWidget {
  final DateTime? initialDate;
  final CycleEntry? existingEntry;

  const _addEntryDialogContent({this.initialDate, this.existingEntry});

  @override
  State<_addEntryDialogContent> createState() => __addEntryDialogContentState();
}

class __addEntryDialogContentState extends State<_addEntryDialogContent> {
  late DateTime _selectedDate;
  late CyclePhase _selectedPhase;
  List<Symptom> _selectedSymptoms = [];
  int? _flowIntensity;
  final TextEditingController _notesController = TextEditingController();

  bool _isDatePickerShowing = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingEntry != null) {
      _selectedDate = widget.existingEntry!.date;
      _selectedPhase = widget.existingEntry!.phase;
      _selectedSymptoms = List.from(widget.existingEntry!.symptoms);
      _flowIntensity = widget.existingEntry!.flowIntensity;
      _notesController.text = widget.existingEntry!.notes ?? '';
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedPhase = CyclePhase.menstrual;
      _selectedSymptoms = [];
      _flowIntensity = null;
      _notesController.text = '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (_isDatePickerShowing) return;

    _isDatePickerShowing = true;

    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: _selectedDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.dark(primary: Colors.pink)),
          child: child!,
        );
      },
    );

    _isDatePickerShowing = false;

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onSymptomsChanged(List<Symptom> symptoms) {
    setState(() {
      _selectedSymptoms = symptoms;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveEntry() async {
    if (_selectedPhase == null) {
      _showError('Please select a cycle phase');
    }

    logger.d("Saving......");

    final entry = CycleEntry(
      date: _selectedDate,
      phase: _selectedPhase,
      flowIntensity: _flowIntensity,
      symptoms: _selectedSymptoms,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.addEntry(entry);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Entry saved for ${formatDateShort(_selectedDate)}'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: BoxConstraints(
        maxWidth: 500,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date selector
                  _buildDateSelector(),
                  SizedBox(height: 20),

                  // // Phase selector
                  // _buildPhaseSelector(),
                  // SizedBox(height: 20),

                  // Symptom selector
                  SymptomSelector(
                    onSymptomsChanged: _onSymptomsChanged,
                    initialSymptoms: _selectedSymptoms,
                  ),
                  SizedBox(height: 20),

                  // Intensity selector
                  _buildFlowIntensitySlider(),
                  SizedBox(height: 20),

                  // Notes field
                  _buildNotesField(),
                ],
              ),
            ),
          ),

          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.pink,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.female, color: Colors.pink.shade100, size: 30),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.existingEntry != null ? 'Edit Entry' : 'Add Period Entry',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.pink, size: 20),
                SizedBox(width: 12),
                Text(
                  formatDateLong(_selectedDate),
                  style: TextStyle(fontSize: 16),
                ),
                Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildPhaseSelector() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Cycle Phase',
  //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //       ),
  //       SizedBox(height: 8),
  //       Wrap(
  //         spacing: 8,
  //         children:
  //             CyclePhase.values.map((phase) {
  //               return ChoiceChip(
  //                 label: Text(
  //                   getPhaseName(phase),
  //                   style: TextStyle(
  //                     color:
  //                         _selectedPhase == phase
  //                             ? Colors.white
  //                             : Colors.white70,
  //                   ),
  //                 ),
  //                 selected: _selectedPhase == phase,
  //                 onSelected: (selected) {
  //                   if (selected) {
  //                     setState(() {
  //                       _selectedPhase = phase;
  //                     });
  //                   }
  //                 },
  //                 selectedColor: getPhaseColor(phase).withValues(alpha: 0.7),
  //               );
  //             }).toList(),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildFlowIntensitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flow Intensity',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: (_flowIntensity ?? 0).toDouble(),
                min: 0,
                max: 5,
                divisions: 5,
                label:
                    _flowIntensity == null
                        ? 'Not Set'
                        : getFlowText(_flowIntensity!),
                onChanged: (value) {
                  setState(() {
                    _flowIntensity = value.toInt();
                    if (_flowIntensity == 0) _flowIntensity = null;
                  });
                },
                activeColor: Colors.pink,
              ),
            ),
            Icon(
              Icons.water_drop,
              color:
                  _flowIntensity == null
                      ? Colors.grey.shade400
                      : Color.lerp(
                        Colors.pink.shade200,
                        Colors.red.shade900,
                        (_flowIntensity! - 1) / 4,
                      ),
            ),
          ],
        ),
        if (_flowIntensity != null)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              getFlowText(_flowIntensity!),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add any notes about your cycle...',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade800, width: 1.5),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.pink, width: 2.0),
            ),
            filled: true,
            fillColor: Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
