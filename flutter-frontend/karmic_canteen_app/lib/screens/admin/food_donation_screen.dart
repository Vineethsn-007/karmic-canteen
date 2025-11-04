// lib/screens/admin/food_donation_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class FoodDonationScreen extends StatefulWidget {
  const FoodDonationScreen({super.key});

  @override
  State<FoodDonationScreen> createState() => _FoodDonationScreenState();
}

class _FoodDonationScreenState extends State<FoodDonationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _snacksController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isSending = false;
  String? _message;
  bool _isError = false;

  // ✅ CONFIGURE YOUR EMAIL HERE
  static const String senderEmail = 'snvineeth10@gmail.com'; // Change this
  static const String senderPassword = 'eynm gjuw lnzb pfme'; // Change this (16-char app password)
  static const String senderName = 'Karmic Canteen';

  @override
  void dispose() {
    _breakfastController.dispose();
    _lunchController.dispose();
    _snacksController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _sendDonationNotification() async {
    final breakfast = int.tryParse(_breakfastController.text) ?? 0;
    final lunch = int.tryParse(_lunchController.text) ?? 0;
    final snacks = int.tryParse(_snacksController.text) ?? 0;
    final total = breakfast + lunch + snacks;

    if (total == 0) {
      _showMessage('Please enter at least one meal count', isError: true);
      return;
    }

    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      // Get all active NGOs
      final ngosSnapshot = await _firestore
          .collection('ngos')
          .where('active', isEqualTo: true)
          .get();

      if (ngosSnapshot.docs.isEmpty) {
        _showMessage('No active NGOs found in database', isError: true);
        setState(() => _isSending = false);
        return;
      }

      // Configure SMTP server (Gmail)
      final smtpServer = gmail(senderEmail, senderPassword);
      
      // For Outlook, use this instead:
      // final smtpServer = hotmail(senderEmail, senderPassword);

      final today = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
      final time = DateFormat('h:mm a').format(DateTime.now());

      int sentCount = 0;
      List<String> failedEmails = [];

      // Send email to each NGO
      for (var ngo in ngosSnapshot.docs) {
        final ngoData = ngo.data();
        final recipientEmail = ngoData['email'] as String;
        final recipientName = ngoData['name'] as String;

        try {
          // Create email message
          final message = Message()
            ..from = Address(senderEmail, senderName)
            ..recipients.add(recipientEmail)
            ..subject = 'Food Donation Available Today - $senderName'
            ..html = _buildEmailHtml(
              recipientName: recipientName,
              today: today,
              time: time,
              breakfast: breakfast,
              lunch: lunch,
              snacks: snacks,
              total: total,
              notes: _notesController.text,
            );

          // Send the email
          await send(message, smtpServer);
          sentCount++;
          print('✓ Email sent to: $recipientEmail');
          
          // Small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 300));
          
        } catch (e) {
          print('✗ Failed to send to $recipientEmail: $e');
          failedEmails.add(recipientEmail);
        }
      }

      // Log the donation
      await _firestore.collection('donations').add({
        'date': FieldValue.serverTimestamp(),
        'breakfast': breakfast,
        'lunch': lunch,
        'snacks': snacks,
        'total': total,
        'notes': _notesController.text,
        'ngoCount': sentCount,
        'failedEmails': failedEmails,
        'status': sentCount > 0 ? 'sent' : 'failed',
      });

      setState(() {
        _isSending = false;
      });

      if (sentCount > 0) {
        _showMessage('✅ Emails successfully sent to $sentCount NGO(s)!');
        
        // Clear form on success
        _breakfastController.clear();
        _lunchController.clear();
        _snacksController.clear();
        _notesController.clear();
      } else {
        _showMessage('❌ Failed to send emails. Check console for errors.', isError: true);
      }

    } catch (e) {
      setState(() {
        _isSending = false;
      });
      _showMessage('❌ Error: $e', isError: true);
      print('Error details: $e');
    }
  }

  String _buildEmailHtml({
    required String recipientName,
    required String today,
    required String time,
    required int breakfast,
    required int lunch,
    required int snacks,
    required int total,
    required String notes,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      line-height: 1.6;
      color: #333;
      margin: 0;
      padding: 0;
      background-color: #f4f4f4;
    }
    .container {
      max-width: 600px;
      margin: 20px auto;
      background: white;
      border-radius: 10px;
      overflow: hidden;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    .header {
      background: linear-gradient(135deg, #FF6B35 0%, #FF8E53 100%);
      color: white;
      padding: 30px 20px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
    }
    .content {
      padding: 30px 20px;
    }
    .greeting {
      font-size: 18px;
      margin-bottom: 20px;
      color: #2c3e50;
    }
    .food-box {
      background: #fff8f3;
      padding: 20px;
      margin: 20px 0;
      border-radius: 8px;
      border-left: 4px solid #FF6B35;
    }
    .food-box h3 {
      margin-top: 0;
      color: #FF6B35;
    }
    .food-item {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid #eee;
    }
    .food-item:last-child {
      border-bottom: none;
    }
    .food-item .label {
      font-weight: 500;
    }
    .food-item .value {
      font-weight: bold;
      color: #FF6B35;
    }
    .total-row {
      background: #FF6B35;
      color: white;
      padding: 15px;
      border-radius: 5px;
      text-align: center;
      font-size: 20px;
      font-weight: bold;
      margin-top: 10px;
    }
    .pickup-box {
      background: #e3f2fd;
      padding: 20px;
      margin: 20px 0;
      border-radius: 8px;
      border-left: 4px solid #2196F3;
    }
    .pickup-box h3 {
      margin-top: 0;
      color: #1976D2;
    }
    .pickup-info {
      margin: 10px 0;
    }
    .pickup-info strong {
      display: inline-block;
      width: 150px;
    }
    .notes-box {
      background: #fff9e6;
      padding: 15px;
      margin: 15px 0;
      border-radius: 5px;
      border-left: 4px solid #FFC107;
    }
    .footer {
      background: #2c3e50;
      color: white;
      padding: 20px;
      text-align: center;
    }
    .footer p {
      margin: 5px 0;
    }
    .cta-button {
      display: inline-block;
      background: #4CAF50;
      color: white;
      padding: 12px 30px;
      text-decoration: none;
      border-radius: 5px;
      margin: 20px 0;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🤝 Food Donation Available</h1>
      <p>Help us reduce food waste today!</p>
    </div>
    
    <div class="content">
      <p class="greeting">Dear $recipientName,</p>
      
      <p>We hope this email finds you well. <strong>$senderName</strong> has leftover food available for donation today that we would love to share with your organization.</p>
      
      <p><strong>📅 Date:</strong> $today<br>
      <strong>🕐 Time Posted:</strong> $time</p>
      
      <div class="food-box">
        <h3>🍽️ Available Food</h3>
        <div class="food-item">
          <span class="label">🌅 Breakfast</span>
          <span class="value">$breakfast portions</span>
        </div>
        <div class="food-item">
          <span class="label">🍽️ Lunch</span>
          <span class="value">$lunch portions</span>
        </div>
        <div class="food-item">
          <span class="label">☕ Snacks</span>
          <span class="value">$snacks portions</span>
        </div>
        <div class="total-row">
          Total: $total portions
        </div>
      </div>
      
      ${notes.isNotEmpty ? '''
      <div class="notes-box">
        <p><strong>📝 Additional Information:</strong></p>
        <p>$notes</p>
      </div>
      ''' : ''}
      
      <div class="pickup-box">
        <h3>📍 Pickup Details</h3>
        <div class="pickup-info">
          <strong>Location:</strong> Karmic Solutions Office Canteen
        </div>
        <div class="pickup-info">
          <strong>Address:</strong> [Your Complete Address Here]
        </div>
        <div class="pickup-info">
          <strong>Available Until:</strong> 7:00 PM today
        </div>
        <div class="pickup-info">
          <strong>Contact Person:</strong> Admin
        </div>
        <div class="pickup-info">
          <strong>Phone:</strong> +91-XXXXXXXXXX
        </div>
      </div>
      
      <p style="text-align: center;">
        <a href="mailto:$senderEmail?subject=Food Donation Confirmation - $today" class="cta-button">
          Confirm Pickup
        </a>
      </p>
      
      <p>Please reply to this email or call us to confirm if you can collect the food today. We want to ensure this food reaches those who need it!</p>
      
      <p>Thank you for being our partner in the fight against food waste and hunger. Together, we're making a difference! 🙏</p>
    </div>
    
    <div class="footer">
      <p><strong>$senderName</strong></p>
      <p>Making a difference, one meal at a time</p>
      <p style="font-size: 12px; margin-top: 15px;">
        This is an automated notification. Please do not reply to this email.<br>
        For inquiries, contact us at $senderEmail
      </p>
    </div>
  </div>
</body>
</html>
    ''';
  }

  void _showMessage(String message, {bool isError = false}) {
    setState(() {
      _message = message;
      _isError = isError;
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _message = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Donation'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      size: 48,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Donate Leftover Food',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the leftover food count to notify registered NGOs via email',
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
            const SizedBox(height: 24),

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

            // Food Count Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leftover Food Count',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildMealInputField(
                      label: 'Breakfast Portions',
                      controller: _breakfastController,
                      icon: Icons.wb_sunny,
                      emoji: '🌅',
                    ),
                    const SizedBox(height: 16),

                    _buildMealInputField(
                      label: 'Lunch Portions',
                      controller: _lunchController,
                      icon: Icons.lunch_dining,
                      emoji: '🍽️',
                    ),
                    const SizedBox(height: 16),

                    _buildMealInputField(
                      label: 'Snacks Portions',
                      controller: _snacksController,
                      icon: Icons.local_cafe,
                      emoji: '☕',
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        hintText: 'e.g., Special instructions, allergen info',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.note),
                        helperText: 'Any special information for NGOs',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Registered NGOs Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.group, color: Color(0xFF21808D)),
                        const SizedBox(width: 12),
                        const Text(
                          'Registered NGOs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('ngos')
                          .where('active', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final ngos = snapshot.data!.docs;

                        if (ngos.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.amber.shade700),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'No active NGOs found. Please add NGOs in Firestore first.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: ngos.map((ngo) {
                            final data = ngo.data() as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          data['email'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Send Button
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendDonationNotification,
              icon: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Sending Emails...' : 'Send Notification to NGOs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
                      'Emails will be sent automatically to all registered NGOs. Make sure to configure your email credentials at the top of the code.',
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
    );
  }

  Widget _buildMealInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String emoji,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        suffixText: emoji,
      ),
    );
  }
}
