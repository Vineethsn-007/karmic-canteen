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
  List<String> _dinner = [];
  
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _snacksController = TextEditingController();
  
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
          _showMessage('Loaded existing menu for $_formattedDate', isError: false);
        } else {
          _breakfast = [];
          _lunch = [];
          _snacks = [];
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
    if (_breakfast.isEmpty && _lunch.isEmpty && _snacks.isEmpty) {
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
        dinner: _dinner,
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

  int get _totalItems => _breakfast.length + _lunch.length + _snacks.length;

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
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ),

                  // Meal Sections
                  _buildMealSection(
                    'Breakfast',
                    '🌅',
                    _breakfast,
                    _breakfastController,
                    'breakfast',
                  ),
                  const SizedBox(height: 16),
                  _buildMealSection(
                    'Lunch',
                    '🌞',
                    _lunch,
                    _lunchController,
                    'lunch',
                  ),
                  const SizedBox(height: 16),
                  _buildMealSection(
                    'Snacks',
                    '🌙',
                    _snacks,
                    _snacksController,
                    'snacks',
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isSaving || _totalItems == 0 ? null : _saveMenu,
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
                            'Save Menu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMealSection(
    String title,
    String emoji,
    List<String> items,
    TextEditingController controller,
    String mealType,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
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
