import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/user_settings.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _cycleLength;
  late int _periodLength;
  bool _isSaving = false;

  bool _notificationsEnabled = true;
  bool _periodReminders = true;
  bool _fertileAlerts = true;
  bool _dailyCheckIns = true;
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _cycleLength = appState.settings.defaultCycleLength;
    _periodLength = appState.settings.periodLength;
    _loadNotificationPreferences();
  }

  void _loadNotificationPreferences() {
    _notificationsEnabled = true;
    _periodReminders = true;
    _fertileAlerts = true;
    _dailyCheckIns = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cycle Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildSliderSetting(
                    title: 'Average Cycle Length',
                    value: _cycleLength,
                    min: 21,
                    max: 35,
                    onChanged:
                        _isSaving
                            ? null
                            : (value) {
                              setState(() {
                                _cycleLength = value;
                              });
                            },
                  ),
                  SizedBox(height: 24),
                  _buildSliderSetting(
                    title: 'Period Length',
                    value: _periodLength,
                    min: 2,
                    max: 10,
                    onChanged:
                        _isSaving
                            ? null
                            : (value) {
                              setState(() {
                                _periodLength = value;
                              });
                            },
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed:
                        _isSaving
                            ? null
                            : () async {
                              setState(() {
                                _isSaving = true;
                              });

                              final appState = Provider.of<AppState>(
                                context,
                                listen: false,
                              );

                              final newSettings = UserSettings(
                                defaultCycleLength: _cycleLength,
                                periodLength: _periodLength,
                                isFirstLaunch: false,
                                lastUpdated: DateTime.now(),
                              );

                              await appState.updateSettings(newSettings);

                              if (!mounted) return;

                              setState(() {
                                _isSaving = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Settings saved successfully!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child:
                        _isSaving
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text('Save Settings'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.pink),
                      SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Enable Notifications'),
                    subtitle: Text('Receive all notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                        if (!value) {
                          _periodReminders = false;
                          _fertileAlerts = false;
                          _dailyCheckIns = false;
                          _disableAllNotifications();
                        } else {
                          _periodReminders = true;
                          _fertileAlerts = true;
                          _dailyCheckIns = true;
                          _enableAllNotifications();
                        }
                      });
                    },
                    activeColor: Colors.pink,
                  ),
                  Divider(),
                  SwitchListTile(
                    title: Text('Period Reminders'),
                    subtitle: Text('Get reminded 3 days before period'),
                    value: _periodReminders && _notificationsEnabled,
                    onChanged:
                        _notificationsEnabled
                            ? (value) {
                              setState(() {
                                _periodReminders = value;
                              });
                              _updateNotificationSettings();
                            }
                            : null,
                    activeColor: Colors.pink,
                  ),
                  SwitchListTile(
                    title: Text('Fertility Alerts'),
                    subtitle: Text('Get alerts for fertile window'),
                    value: _fertileAlerts && _notificationsEnabled,
                    onChanged:
                        _notificationsEnabled
                            ? (value) {
                              setState(() {
                                _fertileAlerts = value;
                              });
                              _updateNotificationSettings();
                            }
                            : null,
                    activeColor: Colors.pink,
                  ),
                  SwitchListTile(
                    title: Text('Daily Check-Ins'),
                    subtitle: Text('Daily symptom tracking reminder'),
                    value: _dailyCheckIns && _notificationsEnabled,
                    onChanged:
                        _notificationsEnabled
                            ? (value) {
                              setState(() {
                                _dailyCheckIns = value;
                              });
                              _updateNotificationSettings();
                            }
                            : null,
                    activeColor: Colors.pink,
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _isLoadingNotifications
                              ? null
                              : () => _sendTestNotification(),
                      icon: Icon(Icons.play_arrow, color: Colors.pink),
                      label: Text('Send Test Notification'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.pink,
                        side: BorderSide(color: Colors.pink),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_isLoadingNotifications)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.pink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required int value,
    required int min,
    required int max,
    required Function(int)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        SizedBox(height: 8),
        Row(
          children: [
            Text('$min'),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                onChanged:
                    onChanged != null
                        ? (newValue) => onChanged(newValue.round())
                        : null,
                activeColor: Colors.pink,
              ),
            ),
            Text('$max'),
          ],
        ),
        Center(
          child: Text(
            '$value days',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
          ),
        ),
      ],
    );
  }

  void _disableAllNotifications() {
    notificationService.cancelAllNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications disabled'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _enableAllNotifications() {
    final appState = Provider.of<AppState>(context, listen: false);
    notificationService.scheduleAllNotifications(appState.db);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications enabled'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _updateNotificationSettings() {
    final appState = Provider.of<AppState>(context, listen: false);
    notificationService.scheduleAllNotifications(appState.db);
  }

  void _sendTestNotification() async {
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      await notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Test Notification',
        body: 'Your notifications are working!',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }
}
