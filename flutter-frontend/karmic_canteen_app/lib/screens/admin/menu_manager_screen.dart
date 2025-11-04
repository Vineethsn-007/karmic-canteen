// lib/screens/admin/menu_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/menu_model.dart';

class MenuManagerScreen extends StatefulWidget {
  const MenuManagerScreen({super.key});

  @override
  State<MenuManagerScreen> createState() => _MenuManagerScreenState();
}

class _MenuManagerScreenState extends State<MenuManagerScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  List<String> _breakfast = [];
  List<String> _lunch = [];
  List<String> _snacks = [];
  List<String> _dinner = []; // ✅ Added
  
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _snacksController = TextEditingController();
  final _dinnerController = TextEditingController(); // ✅ Added
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  @override
  void dispose() {
    _breakfastController.dispose();
    _lunchController.dispose();
    _snacksController.dispose();
    _dinnerController.dispose(); // ✅ Added
    super.dispose();
  }

  String get _dateString => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _formattedDate => DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final menu = await _firestoreService.getMenu(_dateString);
      
      setState(() {
        if (menu != null) {
          _breakfast = List.from(menu.breakfast);
          _lunch = List.from(menu.lunch);
          _snacks = List.from(menu.snacks);
          _dinner = List.from(menu.dinner); // ✅ Added
          _showMessage('Loaded existing menu for $_formattedDate', isError: false);
        } else {
          _breakfast = [];
          _lunch = [];
          _snacks = [];
          _dinner = []; // ✅ Added
          _showMessage('Creating new menu for $_formattedDate', isError: false);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Failed to load menu: $e', isError: true);
    }
  }

  Future<void> _saveMenu() async {
    if (_breakfast.isEmpty && _lunch.isEmpty && _snacks.isEmpty && _dinner.isEmpty) {
      _showMessage('Please add at least one menu item', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      final menu = MenuModel(
        date: _dateString,
        breakfast: _breakfast,
        lunch: _lunch,
        snacks: _snacks,
        dinner: _dinner, // ✅ Added
      );

      await _firestoreService.saveMenu(_dateString, menu);
      
      setState(() {
        _isSaving = false;
      });
      _showMessage('Menu saved successfully for $_formattedDate!');
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showMessage('Failed to save menu: $e', isError: true);
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

  void _addItem(String mealType, String item) {
    if (item.trim().isEmpty) {
      _showMessage('Please enter an item name', isError: true);
      return;
    }

    setState(() {
      switch (mealType) {
        case 'breakfast':
          if (!_breakfast.contains(item)) {
            _breakfast.add(item);
            _breakfastController.clear();
          } else {
            _showMessage('Item already exists', isError: true);
          }
          break;
        case 'lunch':
          if (!_lunch.contains(item)) {
            _lunch.add(item);
            _lunchController.clear();
          } else {
            _showMessage('Item already exists', isError: true);
          }
          break;
        case 'snacks':
          if (!_snacks.contains(item)) {
            _snacks.add(item);
            _snacksController.clear();
          } else {
            _showMessage('Item already exists', isError: true);
          }
          break;
        case 'dinner': // ✅ Added
          if (!_dinner.contains(item)) {
            _dinner.add(item);
            _dinnerController.clear();
          } else {
            _showMessage('Item already exists', isError: true);
          }
          break;
      }
    });
  }

  void _removeItem(String mealType, int index) {
    setState(() {
      switch (mealType) {
        case 'breakfast':
          _breakfast.removeAt(index);
          break;
        case 'lunch':
          _lunch.removeAt(index);
          break;
        case 'snacks':
          _snacks.removeAt(index);
          break;
        case 'dinner': // ✅ Added
          _dinner.removeAt(index);
          break;
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMenu();
    }
  }

  int get _totalItems => _breakfast.length + _lunch.length + _snacks.length + _dinner.length; // ✅ Updated

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
                  // Date Selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📅 Select Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formattedDate),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Total Items: $_totalItems',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF21808D),
                              ),
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

                  // Meal Time Info Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Meal Timings',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTimingRow('🌅 Breakfast', '8:30 AM - 10:00 AM'),
                          _buildTimingRow('🍽️ Lunch', '1:00 PM - 2:30 PM'),
                          _buildTimingRow('☕ Snacks', '5:00 PM - 6:30 PM'),
                          _buildTimingRow('🌙 Dinner', '8:00 PM - 9:30 PM'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meal Sections
                  _buildMealSection(
                    'Breakfast',
                    '🌅',
                    _breakfast,
                    _breakfastController,
                    'breakfast',
                    '8:30 AM - 10:00 AM',
                  ),
                  const SizedBox(height: 16),
                  _buildMealSection(
                    'Lunch',
                    '🌞',
                    _lunch,
                    _lunchController,
                    'lunch',
                    '1:00 PM - 2:30 PM',
                  ),
                  const SizedBox(height: 16),
                  _buildMealSection(
                    'Snacks',
                    '☕',
                    _snacks,
                    _snacksController,
                    'snacks',
                    '5:00 PM - 6:30 PM',
                  ),
                  const SizedBox(height: 16),
                  // ✅ Added Dinner Section
                  _buildMealSection(
                    'Dinner',
                    '🌙',
                    _dinner,
                    _dinnerController,
                    'dinner',
                    '8:00 PM - 9:30 PM',
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton.icon(
                    onPressed: _isSaving || _totalItems == 0 ? null : _saveMenu,
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
                    label: Text(_isSaving ? 'Saving...' : 'Save Menu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21808D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Employees can select meals until 12:30 PM on the previous day.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
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

  Widget _buildTimingRow(String meal, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            meal,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(
    String title,
    String emoji,
    List<String> items,
    TextEditingController controller,
    String mealType,
    String timing,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timing,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text('${items.length} items'),
                  backgroundColor: Colors.teal.shade50,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Add ${title.toLowerCase()} item',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) => _addItem(mealType, value),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addItem(mealType, controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF21808D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No ${title.toLowerCase()} items added yet',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeItem(mealType, entry.key),
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
