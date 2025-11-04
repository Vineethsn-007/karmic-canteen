// lib/screens/admin/analytics_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _totalEmployees = 0;
  int _todayParticipants = 0;
  int _breakfastCount = 0;
  int _lunchCount = 0;
  int _snacksCount = 0;
  int _dinnerCount = 0; // ✅ Added
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get total employees count
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();
      _totalEmployees = usersSnapshot.docs.length;

      // Get today's meal selections
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));
      final selectionsSnapshot = await _firestore
          .collection('mealSelections')
          .doc(today)
          .collection('selections')
          .get();

      int breakfastCount = 0;
      int lunchCount = 0;
      int snacksCount = 0;
      int dinnerCount = 0; // ✅ Added

      for (var doc in selectionsSnapshot.docs) {
        final data = doc.data();
        if (data['breakfast'] == true) breakfastCount++;
        if (data['lunch'] == true) lunchCount++;
        if (data['snacks'] == true) snacksCount++;
        if (data['dinner'] == true) dinnerCount++; // ✅ Added
      }

      setState(() {
        _todayParticipants = selectionsSnapshot.docs.length;
        _breakfastCount = breakfastCount;
        _lunchCount = lunchCount;
        _snacksCount = snacksCount;
        _dinnerCount = dinnerCount; // ✅ Added
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Analytics Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Last updated: ${DateFormat('h:mm a').format(DateTime.now())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Employees',
                            _totalEmployees.toString(),
                            Icons.people,
                            const Color(0xFF21808D),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Today\'s Participants',
                            _todayParticipants.toString(),
                            Icons.how_to_reg,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Total Meals Card - ✅ Updated to include dinner
                    _buildStatCard(
                      'Total Meals Ordered',
                      (_breakfastCount + _lunchCount + _snacksCount + _dinnerCount).toString(),
                      Icons.restaurant,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),

                    // Participation Rate Card
                    _buildParticipationCard(),
                    const SizedBox(height: 24),

                    // Meal Distribution Section
                    const Text(
                      'Today\'s Meal Distribution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pie Chart Card
                    _buildPieChartCard(),
                    const SizedBox(height: 24),

                    // Meal Breakdown Cards
                    const Text(
                      'Meal Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildMealBreakdownCard('🌅 Breakfast', _breakfastCount, Colors.orange),
                    const SizedBox(height: 12),
                    _buildMealBreakdownCard('🍽️ Lunch', _lunchCount, Colors.green),
                    const SizedBox(height: 12),
                    _buildMealBreakdownCard('☕ Snacks', _snacksCount, Colors.purple),
                    const SizedBox(height: 12),
                    // ✅ Added Dinner card
                    _buildMealBreakdownCard('🍲 Dinner', _dinnerCount, Colors.indigo),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationCard() {
    final participationRate = _totalEmployees > 0
        ? (_todayParticipants / _totalEmployees * 100).toStringAsFixed(1)
        : '0.0';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Participation Rate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$participationRate%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF21808D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _totalEmployees > 0 ? _todayParticipants / _totalEmployees : 0,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF21808D)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_todayParticipants of $_totalEmployees employees participating',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Updated to include dinner in pie chart
  Widget _buildPieChartCard() {
    final totalMeals = _breakfastCount + _lunchCount + _snacksCount + _dinnerCount;

    if (totalMeals == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No meal selections yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: _breakfastCount.toDouble(),
                      title: '${(_breakfastCount / totalMeals * 100).toInt()}%',
                      color: Colors.orange,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: _lunchCount.toDouble(),
                      title: '${(_lunchCount / totalMeals * 100).toInt()}%',
                      color: Colors.green,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: _snacksCount.toDouble(),
                      title: '${(_snacksCount / totalMeals * 100).toInt()}%',
                      color: Colors.purple,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // ✅ Added Dinner section
                    PieChartSectionData(
                      value: _dinnerCount.toDouble(),
                      title: '${(_dinnerCount / totalMeals * 100).toInt()}%',
                      color: Colors.indigo,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Legend - ✅ Updated to wrap for 4 items
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem('Breakfast', Colors.orange),
                _buildLegendItem('Lunch', Colors.green),
                _buildLegendItem('Snacks', Colors.purple),
                _buildLegendItem('Dinner', Colors.indigo), // ✅ Added
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ✅ Updated to include dinner in total calculation
  Widget _buildMealBreakdownCard(String title, int count, Color color) {
    final totalMeals = _breakfastCount + _lunchCount + _snacksCount + _dinnerCount;
    final percentage = totalMeals > 0 ? (count / totalMeals * 100).toInt() : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  title.split(' ')[0], // Just the emoji
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.split(' ')[1], // Just the name
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count orders',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
