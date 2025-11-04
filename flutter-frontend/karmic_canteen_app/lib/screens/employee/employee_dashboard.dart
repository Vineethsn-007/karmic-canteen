// lib/screens/employee/employee_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/menu_model.dart';
import '../../widgets/work_mode_selector.dart';
import '../employee/weekly_meal_selection_screen.dart';
import '../employee/festivals_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  MenuModel? _menu;
  Map<String, bool> _selections = {
    'breakfast': false,
    'lunch': false,
    'snacks': false,
    'dinner': false,
  };
  Map<String, bool> _originalSelections = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeadlinePassed = false;
  DateTime? _deadline;
  String? _message;
  bool _isError = false;
  
  String? _workMode;
  bool _isWFH = false;

  @override
  void initState() {
    super.initState();
    _checkWorkMode();
  }

  Future<void> _checkWorkMode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = authProvider.user?.email;
      
      // Always use tomorrow's date
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateString = DateFormat('yyyy-MM-dd').format(tomorrow);

      if (userEmail != null) {
        final workModeDoc = await _firestore
            .collection('workModes')
            .doc(dateString)
            .collection('modes')
            .doc(userEmail)
            .get();

        if (workModeDoc.exists) {
          final mode = workModeDoc.data()?['mode'] ?? 'office';
          setState(() {
            _workMode = mode;
            _isWFH = mode == 'wfh';
          });

          if (!_isWFH) {
            await _loadMenuAndSelections();
            await _scheduleDeadlineReminders();
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            _showWorkModeSelector();
          }
        }
      }
    } catch (e) {
      print('Error checking work mode: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showWorkModeSelector() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WorkModeSelector(
        currentMode: _workMode,
        onModeSelected: _saveWorkMode,
      ),
    );
  }

  Future<void> _quickToggleWorkMode() async {
    if (_isDeadlinePassed) {
      _showMessage('Cannot change work mode after deadline', isError: true);
      return;
    }

    final newMode = _isWFH ? 'office' : 'wfh';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Switch to ${newMode == 'office' ? 'Office' : 'Work From Home'}?'),
        content: Text(
          newMode == 'office'
              ? 'You will be able to select meals for tomorrow.'
              : 'Your meal selections will be cleared and you won\'t receive notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF21808D),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _saveWorkMode(newMode);
    }
  }

  // Add this to employee_dashboard.dart after the work mode toggle section

Widget _buildWeeklyModeButton() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.purple.shade50,
      border: Border(
        bottom: BorderSide(color: Colors.purple.shade200),
      ),
    ),
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WeeklyMealSelectionScreen(),
          ),
        );
      },
      icon: const Icon(Icons.calendar_view_week),
      label: const Text('Plan Weekly Meals'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(double.infinity, 48),
      ),
    ),
  );
}


  Future<void> _saveWorkMode(String mode) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = authProvider.user?.email;
      
      // Always use tomorrow's date
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateString = DateFormat('yyyy-MM-dd').format(tomorrow);

      if (userEmail != null) {
        await _firestore
            .collection('workModes')
            .doc(dateString)
            .collection('modes')
            .doc(userEmail)
            .set({
          'email': userEmail,
          'mode': mode,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _workMode = mode;
          _isWFH = mode == 'wfh';
        });

        _showMessage('Work mode set to ${mode == 'office' ? 'Office' : 'Work From Home'}');

        if (!_isWFH) {
          await _loadMenuAndSelections();
          await _scheduleDeadlineReminders();
        }
      }
    } catch (e) {
      _showMessage('Failed to save work mode: $e', isError: true);
    }
  }

  Future<void> _loadMenuAndSelections() async {
    if (_isWFH) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Always use tomorrow's date for meals
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateString = DateFormat('yyyy-MM-dd').format(tomorrow);

      final menu = await _firestoreService.getMenu(dateString);

      final deadlineDoc = await _firestore.collection('settings').doc('deadline').get();
      DateTime? deadlineTime;

      if (deadlineDoc.exists) {
        final deadlineHour = deadlineDoc.data()?['deadlineHour'] ?? 12; // Changed to 12
        final deadlineMinute = deadlineDoc.data()?['deadlineMinute'] ?? 30; // Changed to 30

        // Deadline is TODAY at the set time (12:30 PM)
        final now = DateTime.now();
        deadlineTime = DateTime(
          now.year,
          now.month,
          now.day,
          deadlineHour,
          deadlineMinute,
        );

        if (now.isAfter(deadlineTime)) {
          setState(() {
            _isDeadlinePassed = true;
          });
        }
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = authProvider.user?.email;

      if (userEmail != null) {
        final selectionDoc = await _firestore
            .collection('mealSelections')
            .doc(dateString)
            .collection('selections')
            .doc(userEmail)
            .get();

        if (selectionDoc.exists) {
          final data = selectionDoc.data()!;
          setState(() {
            _selections = {
              'breakfast': data['breakfast'] ?? false,
              'lunch': data['lunch'] ?? false,
              'snacks': data['snacks'] ?? false,
              'dinner': data['dinner'] ?? false,
            };
            _originalSelections = Map.from(_selections);
          });
        }
      }

      setState(() {
        _menu = menu;
        _deadline = deadlineTime;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Failed to load menu: $e', isError: true);
    }
  }

  Future<void> _scheduleDeadlineReminders() async {
    if (_isWFH) return;

    try {
      final deadlineDoc = await _firestore.collection('settings').doc('deadline').get();
      
      if (deadlineDoc.exists) {
        final deadlineHour = deadlineDoc.data()?['deadlineHour'] ?? 12;
        final deadlineMinute = deadlineDoc.data()?['deadlineMinute'] ?? 30;
        
        final now = DateTime.now();
        
        // Deadline is today at 12:30 PM
        final deadlineTime = DateTime(
          now.year,
          now.month,
          now.day,
          deadlineHour,
          deadlineMinute,
        );
        
        final reminderTime = deadlineTime.subtract(const Duration(minutes: 10));
        
        if (now.isBefore(reminderTime)) {
          await NotificationService.scheduleNotification(
            id: 1,
            title: 'Meal Selection Reminder',
            body: 'Only 10 minutes left to select your meals for tomorrow!',
            scheduledTime: reminderTime,
          );
        }
      }
    } catch (e) {
      print('Error scheduling reminders: $e');
    }
  }

  Future<void> _saveSelections() async {
    if (_isWFH) return;

    if (_isDeadlinePassed) {
      _showMessage('deadlinePassed'.tr(), isError: true);
      return;
    }

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

      // Always use tomorrow's date
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateString = DateFormat('yyyy-MM-dd').format(tomorrow);
      
      await _firestore
          .collection('mealSelections')
          .doc(dateString)
          .collection('selections')
          .doc(userEmail)
          .set({
        'email': userEmail,
        'breakfast': _selections['breakfast'],
        'lunch': _selections['lunch'],
        'snacks': _selections['snacks'],
        'dinner': _selections['dinner'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _originalSelections = Map.from(_selections);
        _isSaving = false;
      });

      _showMessage('mealsSaved'.tr());

      await NotificationService.showNotification(
        title: 'Meal Selection Saved',
        body: 'Your meal preferences for tomorrow have been saved successfully!',
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showMessage('Failed to save selections: $e', isError: true);
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

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'language'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLanguageTile('English', '🇬🇧', const Locale('en')),
            const Divider(),
            _buildLanguageTile('[translate:हिंदी]', '🇮🇳', const Locale('hi')),
            const Divider(),
            _buildLanguageTile('[translate:ಕನ್ನಡ]', '🇮🇳', const Locale('kn')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(String language, String flag, Locale locale) {
    final isSelected = context.locale == locale;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 32)),
      title: Text(
        language,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF21808D))
          : null,
      selected: isSelected,
      selectedTileColor: Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () async {
        await context.setLocale(locale);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to $language'),
              duration: const Duration(seconds: 2),
            ),
          );
          setState(() {});
        }
      },
    );
  }

  String _formattedDate() {
    // Always show tomorrow's date
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateFormat('EEEE, MMMM d').format(tomorrow);
  }

  String _getTimeRemaining() {
    if (_deadline == null) return '';
    
    final now = DateTime.now();
    final difference = _deadline!.difference(now);
    
    if (difference.isNegative) return 'deadlinePassed'.tr();
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours h $minutes min remaining';
    }
    return '$minutes min remaining';
  }

  // ✅ FIXED: Added dinner check
  bool _hasUnsavedChanges() {
    return _selections['breakfast'] != _originalSelections['breakfast'] ||
        _selections['lunch'] != _originalSelections['lunch'] ||
        _selections['snacks'] != _originalSelections['snacks'] ||
        _selections['dinner'] != _originalSelections['dinner']; // Added this line
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_workMode == null ? 'Dashboard' : (_isWFH ? 'Dashboard' : 'selectYourMeals'.tr())),
        actions: [
          // Add this button to employee_dashboard.dart app bar actions

IconButton(
  icon: const Icon(Icons.celebration),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FestivalsScreen(),
      ),
    );
  },
  tooltip: 'Events & Celebrations',
),

          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageSelector,
            tooltip: 'language'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
            tooltip: 'logout'.tr(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workMode == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (_workMode != null) _buildWorkModeToggle(),
                     _buildWeeklyModeButton(),
                    Expanded(
                      child: _isWFH
                          ? _buildWFHScreen()
                          : _menu == null
                              ? _buildNoMenuCard()
                              : RefreshIndicator(
                                  onRefresh: _loadMenuAndSelections,
                                  child: SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _buildHeaderCard(),
                                        const SizedBox(height: 16),
                                        if (_message != null) _buildMessageCard(),
                                        if (_message != null) const SizedBox(height: 16),
                                        _buildMealSection('breakfast'.tr(), _menu!.breakfast, 'breakfast', '🌅'),
                                        const SizedBox(height: 16),
                                        _buildMealSection('lunch'.tr(), _menu!.lunch, 'lunch', '🍽️'),
                                        const SizedBox(height: 16),
                                        _buildMealSection('snacks'.tr(), _menu!.snacks, 'snacks', '☕'),
                                        const SizedBox(height: 16),
                                        // ✅ FIXED: Changed emoji from 🌙 to 🍲
                                        _buildMealSection('dinner'.tr(), _menu!.dinner, 'dinner', '🍲'),
                                        const SizedBox(height: 24),
                                        _buildSummaryCard(),
                                        const SizedBox(height: 16),
                                        _buildSaveButton(),
                                        const SizedBox(height: 16),
                                        _buildDeadlineInfo(),
                                      ],
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildWorkModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isWFH ? Colors.blue.shade50 : const Color(0xFF21808D).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _isWFH ? Colors.blue.shade200 : const Color(0xFF21808D).withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isWFH ? Colors.blue.shade100 : const Color(0xFF21808D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isWFH ? Icons.home : Icons.domain,
              color: _isWFH ? Colors.blue.shade700 : const Color(0xFF21808D),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isWFH ? 'Work From Home' : 'Office',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isWFH ? Colors.blue.shade900 : const Color(0xFF21808D),
                  ),
                ),
                Text(
                  _isWFH ? 'Meal selection disabled' : 'Select your meals for tomorrow',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          if (!_isDeadlinePassed)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _quickToggleWorkMode,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isWFH ? const Color(0xFF21808D) : Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isWFH ? Icons.domain : Icons.home,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isWFH ? 'Go to Office' : 'Go WFH',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade700,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Locked',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWFHScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home_work,
                    size: 64,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Work From Home',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Meal selection is not available for Work From Home employees.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Switch to Office mode using the toggle above to select meals for tomorrow.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isDeadlinePassed
                              ? 'Deadline has passed. You cannot change work mode now.'
                              : 'Tap the toggle button above to switch to Office mode.',
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
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNoMenuCard() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'noMenuAvailable'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'menuNotPublished'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF21808D)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'selectYourMeals'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'For tomorrow: ${_formattedDate()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_deadline != null && !_isDeadlinePassed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${_getTimeRemaining()} (deadline today at 12:30 PM)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard() {
    return Container(
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
    );
  }

  Widget _buildMealSection(String title, List<String> items, String mealType, String emoji) {
    final isSelected = _selections[mealType] == true;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'selected'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'No items available',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Color(0xFF21808D)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isDeadlinePassed
                  ? null
                  : () {
                      setState(() {
                        _selections[mealType] = !isSelected;
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.red.shade400 : const Color(0xFF21808D),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isSelected ? 'Remove' : 'select'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final selectedCount = _selections.values.where((v) => v).length;
    
    return Card(
      color: const Color(0xFF21808D).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Selection Summary',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Meals Selected', style: TextStyle(fontSize: 14)),
                Text(
                  selectedCount.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF21808D),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('status'.tr(), style: const TextStyle(fontSize: 14)),
                Text(
                  _hasUnsavedChanges() ? 'unsavedChanges'.tr() : 'saved'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _hasUnsavedChanges() ? Colors.orange.shade700 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final canSave = _hasUnsavedChanges() && !_isDeadlinePassed && !_isSaving;
    
    return ElevatedButton(
      onPressed: canSave ? _saveSelections : null,
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
          : Text(
              _hasUnsavedChanges() ? 'savePreferences'.tr() : 'noChanges'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildDeadlineInfo() {
    if (_deadline == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDeadlinePassed ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isDeadlinePassed ? Colors.red.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isDeadlinePassed ? Icons.lock_outline : Icons.info_outline,
            color: _isDeadlinePassed ? Colors.red.shade700 : Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isDeadlinePassed
                  ? 'selectionDeadline'.tr()
                  : 'You can modify your selection until ${DateFormat('h:mm a').format(_deadline!)} today',
              style: TextStyle(
                fontSize: 12,
                color: _isDeadlinePassed ? Colors.red.shade700 : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
