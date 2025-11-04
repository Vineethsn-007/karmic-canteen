// lib/screens/employee/weekly_meal_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class WeeklyMealSelectionScreen extends StatefulWidget {
  const WeeklyMealSelectionScreen({super.key});

  @override
  State<WeeklyMealSelectionScreen> createState() => _WeeklyMealSelectionScreenState();
}

class _WeeklyMealSelectionScreenState extends State<WeeklyMealSelectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Store selections for each day of the week
  Map<String, Map<String, bool>> weeklySelections = {};
  Map<String, bool> weeklyWorkModes = {}; // Track work mode for each day
  List<DateTime> weekDates = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _message;
  bool _isError = false;
  int _deadlineHour = 12;
  int _deadlineMinute = 30;

  @override
  void initState() {
    super.initState();
    _initializeWeek();
    _loadDeadlineSettings();
    _loadWeeklySelections();
  }

  void _initializeWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get next 7 days starting from tomorrow
    for (int i = 1; i <= 7; i++) {
      weekDates.add(today.add(Duration(days: i)));
    }
    
    // Initialize selections for each day
    for (var date in weekDates) {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      weeklySelections[dateString] = {
        'breakfast': false,
        'lunch': false,
        'snacks': false,
        'dinner': false,
      };
      weeklyWorkModes[dateString] = false; // false = office, true = wfh
    }
  }

  Future<void> _loadDeadlineSettings() async {
    try {
      final deadlineDoc = await _firestore.collection('settings').doc('deadline').get();
      if (deadlineDoc.exists) {
        setState(() {
          _deadlineHour = deadlineDoc.data()?['deadlineHour'] ?? 12;
          _deadlineMinute = deadlineDoc.data()?['deadlineMinute'] ?? 30;
        });
      }
    } catch (e) {
      print('Error loading deadline settings: $e');
    }
  }

  Future<void> _loadWeeklySelections() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = authProvider.user?.email;

      if (userEmail != null) {
        for (var date in weekDates) {
          final dateString = DateFormat('yyyy-MM-dd').format(date);
          
          // Load meal selections
          final selectionDoc = await _firestore
              .collection('mealSelections')
              .doc(dateString)
              .collection('selections')
              .doc(userEmail)
              .get();

          if (selectionDoc.exists) {
            final data = selectionDoc.data()!;
            setState(() {
              weeklySelections[dateString] = {
                'breakfast': data['breakfast'] ?? false,
                'lunch': data['lunch'] ?? false,
                'snacks': data['snacks'] ?? false,
                'dinner': data['dinner'] ?? false,
              };
            });
          }

          // Load work mode
          final workModeDoc = await _firestore
              .collection('workModes')
              .doc(dateString)
              .collection('modes')
              .doc(userEmail)
              .get();

          if (workModeDoc.exists) {
            final mode = workModeDoc.data()?['mode'] ?? 'office';
            setState(() {
              weeklyWorkModes[dateString] = mode == 'wfh';
            });
          }
        }
      }
    } catch (e) {
      _showMessage('Error loading selections: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWeeklySelections() async {
    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = authProvider.user?.email;

      if (userEmail == null) {
        throw Exception('User not logged in');
      }

      final now = DateTime.now();
      int savedCount = 0;
      List<String> skippedDays = [];

      for (var date in weekDates) {
        final dateString = DateFormat('yyyy-MM-dd').format(date);
        
        // Deadline is at 12:30 PM on the day before
        final previousDay = date.subtract(const Duration(days: 1));
        final deadline = DateTime(
          previousDay.year,
          previousDay.month,
          previousDay.day,
          _deadlineHour,
          _deadlineMinute,
        );

        if (now.isAfter(deadline)) {
          skippedDays.add(DateFormat('MMM d').format(date));
          continue;
        }

        // Save work mode
        await _firestore
            .collection('workModes')
            .doc(dateString)
            .collection('modes')
            .doc(userEmail)
            .set({
          'email': userEmail,
          'mode': weeklyWorkModes[dateString]! ? 'wfh' : 'office',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Save meal selections only if not WFH
        if (!weeklyWorkModes[dateString]!) {
          await _firestore
              .collection('mealSelections')
              .doc(dateString)
              .collection('selections')
              .doc(userEmail)
              .set({
            'email': userEmail,
            'breakfast': weeklySelections[dateString]!['breakfast'],
            'lunch': weeklySelections[dateString]!['lunch'],
            'snacks': weeklySelections[dateString]!['snacks'],
            'dinner': weeklySelections[dateString]!['dinner'],
            'timestamp': FieldValue.serverTimestamp(),
            'selectionType': 'weekly',
          });
        }

        savedCount++;
      }

      setState(() => _isSaving = false);

      if (skippedDays.isEmpty) {
        _showMessage('✅ Weekly selections saved successfully for all 7 days!');
      } else {
        _showMessage(
          '✅ Saved $savedCount day(s). Skipped (deadline passed): ${skippedDays.join(", ")}',
        );
      }
      
    } catch (e) {
      setState(() => _isSaving = false);
      _showMessage('❌ Failed to save: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    setState(() {
      _message = message;
      _isError = isError;
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _message = null);
      }
    });
  }

  bool _isDeadlinePassed(DateTime date) {
    final now = DateTime.now();
    final previousDay = date.subtract(const Duration(days: 1));
    final deadline = DateTime(
      previousDay.year,
      previousDay.month,
      previousDay.day,
      _deadlineHour,
      _deadlineMinute,
    );
    return now.isAfter(deadline);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Selection'),
        backgroundColor: const Color(0xFF21808D),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Card
                        Card(
                          color: const Color(0xFF21808D).withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  size: 48,
                                  color: Color(0xFF21808D),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Plan Your Week',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Select meals and work mode for the next 7 days. You can edit until 12:30 PM on the previous day.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Message Card
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
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Set work mode first. Meal selection is only available for Office days.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Days List
                        ...weekDates.map((date) => _buildDayCard(date)),
                      ],
                    ),
                  ),
                ),

                // Bottom Save Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveWeeklySelections,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Weekly Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21808D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDayCard(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final dayName = DateFormat('EEEE').format(date);
    final dateFormatted = DateFormat('MMM d, yyyy').format(date);
    final isWFH = weeklyWorkModes[dateString]!;
    final isLocked = _isDeadlinePassed(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isWFH 
                  ? Colors.blue.shade50 
                  : const Color(0xFF21808D).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWFH ? Colors.blue.shade100 : const Color(0xFF21808D).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: isWFH ? Colors.blue.shade700 : const Color(0xFF21808D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dateFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Locked',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Work Mode Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Work Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          isWFH ? 'WFH' : 'Office',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isWFH ? Colors.blue.shade700 : const Color(0xFF21808D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: isWFH,
                          onChanged: isLocked
                              ? null
                              : (value) {
                                  setState(() {
                                    weeklyWorkModes[dateString] = value;
                                    // Clear meal selections if switching to WFH
                                    if (value) {
                                      weeklySelections[dateString] = {
                                        'breakfast': false,
                                        'lunch': false,
                                        'snacks': false,
                                        'dinner': false,
                                      };
                                    }
                                  });
                                },
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Meal Selections (only if Office mode and not locked)
                if (!isWFH && !isLocked) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Meal Selection',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMealCheckbox('🌅 Breakfast', 'breakfast', dateString),
                  _buildMealCheckbox('🍽️ Lunch', 'lunch', dateString),
                  _buildMealCheckbox('☕ Snacks', 'snacks', dateString),
                  _buildMealCheckbox('🍲 Dinner', 'dinner', dateString),
                ] else if (!isWFH && isLocked) ...[
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_clock, color: Colors.amber.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Deadline passed. Cannot modify selections.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.home, color: Colors.blue.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Work From Home - Meal selection not available',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCheckbox(String label, String mealType, String dateString) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: weeklySelections[dateString]![mealType],
      onChanged: (value) {
        setState(() {
          weeklySelections[dateString]![mealType] = value ?? false;
        });
      },
      activeColor: const Color(0xFF21808D),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
