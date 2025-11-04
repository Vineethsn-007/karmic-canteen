// lib/screens/admin/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/firestore_service.dart';
import '../../models/menu_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  Map<String, dynamic>? _reportData;
  MenuModel? _menu;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isDownloading = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  String get _dateString => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _formattedDate => DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final menu = await _firestoreService.getMenu(_dateString);
      
      setState(() {
        _menu = menu;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Failed to load data: $e', isError: true);
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _message = null;
    });

    try {
      final reportData = await _firestoreService.getMealSelections(_dateString);
      
      setState(() {
        _reportData = reportData;
        _isGenerating = false;
      });

      if (reportData['totalParticipants'] == 0) {
        _showMessage(
          'No meal selections found for $_formattedDate. Employees may not have made selections yet.',
          isError: true,
        );
      } else {
        _showMessage(
          'Report generated successfully! Found ${reportData['totalParticipants']} employee(s).',
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _showMessage('Failed to generate report: $e', isError: true);
    }
  }

  Future<void> _downloadReport() async {
    if (_reportData == null) {
      _showMessage('Please generate a report first', isError: true);
      return;
    }

    setState(() {
      _isDownloading = true;
      _message = null;
    });

    try {
      List<List<dynamic>> rows = [];
      
      // Header
      rows.add(['Karmic Canteen - Meal Selection Report']);
      rows.add(['Date: $_formattedDate']);
      rows.add(['Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}']);
      rows.add([]);

      // Summary
      rows.add(['Summary']);
      rows.add(['Total Participants', _reportData!['totalParticipants'] ?? 0]);
      rows.add(['Breakfast Selections', _reportData!['breakfast'] ?? 0]);
      rows.add(['Lunch Selections', _reportData!['lunch'] ?? 0]);
      rows.add(['Snacks Selections', _reportData!['snacks'] ?? 0]);
      rows.add(['Dinner Selections', _reportData!['dinner'] ?? 0]); // ✅ Added
      rows.add([]);

      // Menu
      if (_menu != null) {
        rows.add(['Menu Items']);
        rows.add(['Breakfast', 'Lunch', 'Snacks', 'Dinner']); // ✅ Added Dinner column
        
        final maxItems = [
          _menu!.breakfast.length,
          _menu!.lunch.length,
          _menu!.snacks.length,
          _menu!.dinner.length, // ✅ Added
        ].reduce((a, b) => a > b ? a : b);
        
        for (int i = 0; i < maxItems; i++) {
          rows.add([
            i < _menu!.breakfast.length ? _menu!.breakfast[i] : '',
            i < _menu!.lunch.length ? _menu!.lunch[i] : '',
            i < _menu!.snacks.length ? _menu!.snacks[i] : '',
            i < _menu!.dinner.length ? _menu!.dinner[i] : '', // ✅ Added
          ]);
        }
        rows.add([]);
      }

      // Participants
      if (_reportData!['participants'] != null) {
        rows.add(['Employee Details']);
        rows.add(['#', 'Email', 'Breakfast', 'Lunch', 'Snacks', 'Dinner']); // ✅ Added Dinner column
        
        final participants = _reportData!['participants'] as List;
        for (int i = 0; i < participants.length; i++) {
          final participant = participants[i];
          rows.add([
            i + 1,
            participant['email'] ?? '',
            participant['breakfast'] == true ? 'Yes' : 'No',
            participant['lunch'] == true ? 'Yes' : 'No',
            participant['snacks'] == true ? 'Yes' : 'No',
            participant['dinner'] == true ? 'Yes' : 'No', // ✅ Added
          ]);
        }
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'meal_report_$_dateString.csv';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(csv);

      setState(() {
        _isDownloading = false;
      });

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Meal Selection Report for $_formattedDate',
      );

      _showMessage('Report downloaded successfully!');
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      _showMessage('Failed to download report: $e', isError: true);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _reportData = null;
      });
      _loadReport();
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

  // ✅ Updated to include dinner
  int get _totalMeals {
    if (_reportData == null) return 0;
    return (_reportData!['breakfast'] ?? 0) +
        (_reportData!['lunch'] ?? 0) +
        (_reportData!['snacks'] ?? 0) +
        (_reportData!['dinner'] ?? 0); // Added
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Selector & Controls
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating ? null : _generateReport,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(_isGenerating ? 'Generating...' : 'Generate Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF21808D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _reportData == null || _isDownloading
                              ? null
                              : _downloadReport,
                          icon: _isDownloading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: const Text('CSV'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ],
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

            // Report Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_reportData == null)
              _buildNoReportCard()
            else
              ...[
                _buildStatsGrid(),
                const SizedBox(height: 16),
                if (_menu != null) _buildMenuReference(),
                if (_menu != null) const SizedBox(height: 16),
                if (_reportData!['participants'] != null &&
                    (_reportData!['participants'] as List).isNotEmpty)
                  _buildParticipantsTable(),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoReportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Report Generated',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Generate Report" to view meal selection statistics',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Updated to show all 4 meals in a 2x2 grid
  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Breakfast',
                '🌅',
                _reportData!['breakfast'] ?? 0,
                Colors.orange.shade100,
                Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Lunch',
                '🍽️',
                _reportData!['lunch'] ?? 0,
                Colors.blue.shade100,
                Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Snacks',
                '☕',
                _reportData!['snacks'] ?? 0,
                Colors.purple.shade100,
                Colors.purple.shade700,
              ),
            ),
            const SizedBox(width: 12),
            // ✅ Added Dinner card
            Expanded(
              child: _buildStatCard(
                'Dinner',
                '🍲',
                _reportData!['dinner'] ?? 0,
                Colors.indigo.shade100,
                Colors.indigo.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Total card spans full width
        _buildStatCard(
          'Total Meals',
          '📊',
          _totalMeals,
          Colors.teal.shade100,
          const Color(0xFF21808D),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String emoji,
    int count,
    Color backgroundColor,
    Color textColor,
  ) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              label == 'Total Meals' ? 'meals' : 'employees',
              style: TextStyle(
                fontSize: 11,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Updated to show all 4 meal types
  Widget _buildMenuReference() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Menu for this Day',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildMenuSection('🌅 Breakfast', _menu!.breakfast),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMenuSection('🍽️ Lunch', _menu!.lunch),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildMenuSection('☕ Snacks', _menu!.snacks),
                ),
                const SizedBox(width: 12),
                // ✅ Added Dinner section
                Expanded(
                  child: _buildMenuSection('🍲 Dinner', _menu!.dinner),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text(
            'No items',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          )
        else
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Color(0xFF21808D)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // ✅ Updated to show dinner column
  Widget _buildParticipantsTable() {
    final participants = _reportData!['participants'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👥 Participants (${participants.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('🌅')),
                  DataColumn(label: Text('🍽️')),
                  DataColumn(label: Text('☕')),
                  DataColumn(label: Text('🍲')), // ✅ Added Dinner column
                ],
                rows: participants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final participant = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(participant['email'] ?? '')),
                      DataCell(_buildCheckIcon(participant['breakfast'] == true)),
                      DataCell(_buildCheckIcon(participant['lunch'] == true)),
                      DataCell(_buildCheckIcon(participant['snacks'] == true)),
                      DataCell(_buildCheckIcon(participant['dinner'] == true)), // ✅ Added
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckIcon(bool isSelected) {
    return Icon(
      isSelected ? Icons.check_circle : Icons.cancel,
      color: isSelected ? Colors.green : Colors.red,
      size: 20,
    );
  }
}
