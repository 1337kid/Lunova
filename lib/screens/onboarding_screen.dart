import 'package:flutter/material.dart';
import 'package:lunova/screens/main_screen.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/database_service.dart';
import '../models/user_settings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  int _cycleLength = 28;
  int _periodLength = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade900, Colors.pink.shade900.withAlpha(50)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Spacer(flex: 1),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.shade600,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.nightlight_outlined,
                    size: 60,
                    color: Colors.pink,
                  ),
                ),
                SizedBox(height: 24),

                Text(
                  'Welcome To Lunova',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12),

                Text(
                  'Let\'s personalize your experience',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade300),
                  textAlign: TextAlign.center,
                ),

                Spacer(flex: 1),

                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildSliderCard(
                            title: 'Average Cycle Length',
                            subtitle: 'Days between periods (typically 21-35)',
                            value: _cycleLength,
                            min: 21,
                            max: 35,
                            onChanged: (value) {
                              setState(() {
                                _cycleLength = value.round();
                              });
                            },
                            icon: Icons.timeline,
                          ),

                          SizedBox(height: 20),

                          // Period Length
                          _buildSliderCard(
                            title: 'Period Length',
                            subtitle: 'How many days does your period last?',
                            value: _periodLength,
                            min: 2,
                            max: 10,
                            onChanged: (value) {
                              setState(() {
                                _periodLength = value.round();
                              });
                            },
                            icon: Icons.water_drop,
                          ),

                          SizedBox(height: 20),

                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade900.withAlpha(90),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.pink, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You can change these settings later in the app',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: _saveAndContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink.shade700,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required Function(double) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.pink),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 10),

        Row(
          children: [
            Text('$min', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                onChanged: onChanged,
                activeColor: Colors.pink,
              ),
            ),
            Text('$max', style: TextStyle(fontSize: 12)),
          ],
        ),

        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.pink.shade800,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$value days',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade200,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      final db = appState.db;

      final settings = UserSettings(
        defaultCycleLength: _cycleLength,
        periodLength: _periodLength,
        isFirstLaunch: false,
        lastUpdated: DateTime.now(),
      );

      await db.saveSettings(settings);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    }
  }
}
