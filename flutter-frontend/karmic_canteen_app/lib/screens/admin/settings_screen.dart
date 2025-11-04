// lib/screens/admin/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/language_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _deadlineHour = 21; // Changed to 9 PM (21:00)
  int _deadlineMinute = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final settingsRef = _firestore.collection('settings').doc('deadline');
      final settingsSnap = await settingsRef.get();

      if (settingsSnap.exists) {
        final data = settingsSnap.data()!;
        setState(() {
          _deadlineHour = data['deadlineHour'] ?? 21;
          _deadlineMinute = data['deadlineMinute'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Failed to load settings: $e', isError: true);
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      final settingsRef = _firestore.collection('settings').doc('deadline');
      await settingsRef.set({
        'deadlineHour': _deadlineHour,
        'deadlineMinute': _deadlineMinute,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSaving = false;
      });
      _showMessage('Settings saved successfully!');
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showMessage('Failed to save settings: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    setState(() {
      _message = message;
      _isError = isError;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _message = null;
        });
      }
    });
  }

  void _setPreset(int hour, int minute) {
    setState(() {
      _deadlineHour = hour;
      _deadlineMinute = minute;
    });
  }

  String _formatTime() {
    final hour = _deadlineHour == 0 ? 12 : _deadlineHour > 12 ? _deadlineHour - 12 : _deadlineHour;
    final period = _deadlineHour >= 12 ? 'PM' : 'AM';
    return '$hour:${_deadlineMinute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.settings, color: Color(0xFF21808D)),
                              SizedBox(width: 12),
                              Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Configure app settings and preferences',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message
                  if (_message != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isError ? Colors.red.shade200 : Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isError ? Icons.error_outline : Icons.check_circle_outline,
                            color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Language Selector Section
                  const LanguageSelector(),
                  const SizedBox(height: 24),

                  // Deadline Settings Section Header
                  const Text(
                    'Meal Selection Deadline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set the cutoff time for employees to select meals for the next day. After this time today, selections cannot be modified.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Deadline Display
                  Card(
                    color: const Color(0xFF21808D).withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.alarm, color: const Color(0xFF21808D), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Deadline Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatTime(),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF21808D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Today (same day as selection)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Picker Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Set Deadline Time',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Hour Picker
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hour (0-23)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: '21',
                                      ),
                                      controller: TextEditingController(
                                        text: _deadlineHour.toString(),
                                      ),
                                      onChanged: (value) {
                                        final hour = int.tryParse(value);
                                        if (hour != null && hour >= 0 && hour <= 23) {
                                          setState(() {
                                            _deadlineHour = hour;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Minute Picker
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Minute (0-59)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: '00',
                                      ),
                                      controller: TextEditingController(
                                        text: _deadlineMinute.toString().padLeft(2, '0'),
                                      ),
                                      onChanged: (value) {
                                        final minute = int.tryParse(value);
                                        if (minute != null && minute >= 0 && minute <= 59) {
                                          setState(() {
                                            _deadlineMinute = minute;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Presets Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Presets (Evening Times)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPresetButton('6:00 PM', 18, 0),
                              _buildPresetButton('7:00 PM', 19, 0),
                              _buildPresetButton('8:00 PM', 20, 0),
                              _buildPresetButton('9:00 PM', 21, 0),
                              _buildPresetButton('10:00 PM', 22, 0),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Example Timeline Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timeline, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Example Timeline',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTimelineItem(
                            'Monday Morning - Evening',
                            'Employees select meals for Tuesday',
                            Icons.restaurant_menu,
                            Colors.green,
                          ),
                          _buildTimelineItem(
                            'Monday ${_formatTime()}',
                            'DEADLINE - No more changes allowed',
                            Icons.lock_clock,
                            Colors.orange,
                          ),
                          _buildTimelineItem(
                            'Tuesday 12:00 PM',
                            'Meals are served',
                            Icons.dinner_dining,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21808D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Info Text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'The deadline is TODAY at ${_formatTime()}. Employees must select meals before this time for tomorrow\'s service.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPresetButton(String label, int hour, int minute) {
    final isSelected = _deadlineHour == hour && _deadlineMinute == minute;
    
    return OutlinedButton(
      onPressed: () => _setPreset(hour, minute),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF21808D).withOpacity(0.1) : null,
        side: BorderSide(
          color: isSelected ? const Color(0xFF21808D) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF21808D) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String time, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
