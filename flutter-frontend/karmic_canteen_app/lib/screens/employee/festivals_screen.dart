// lib/screens/employee/festivals_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/festival_model.dart';

class FestivalsScreen extends StatefulWidget {
  const FestivalsScreen({super.key});

  @override
  State<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends State<FestivalsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _respondToRSVP(String festivalId, bool attending) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = authProvider.user?.email;

      if (userEmail == null) return;

      // Check current RSVP status
      final currentRSVP = await _firestore
          .collection('festivals')
          .doc(festivalId)
          .collection('rsvps')
          .doc(userEmail)
          .get();

      final wasAttending = currentRSVP.exists 
          ? (currentRSVP.data()?['attending'] ?? false)
          : false;

      // Update RSVP
      await _firestore
          .collection('festivals')
          .doc(festivalId)
          .collection('rsvps')
          .doc(userEmail)
          .set({
        'email': userEmail,
        'attending': attending,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update attendee count
      if (attending && !wasAttending) {
        // New attendee
        await _firestore.collection('festivals').doc(festivalId).update({
          'attendeesCount': FieldValue.increment(1),
        });
      } else if (!attending && wasAttending) {
        // Removed attendee
        await _firestore.collection('festivals').doc(festivalId).update({
          'attendeesCount': FieldValue.increment(-1),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attending ? '✅ RSVP confirmed!' : '❌ RSVP declined'),
            duration: const Duration(seconds: 2),
            backgroundColor: attending ? Colors.green : Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to respond: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userEmail = authProvider.user?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Celebrations'),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('festivals')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading events',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming events',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final festivals = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: festivals.length,
            itemBuilder: (context, index) {
              final festivalDoc = festivals[index];
              final festival = FestivalModel.fromFirestore(
                festivalDoc.data() as Map<String, dynamic>,
                festivalDoc.id,
              );

              return _buildFestivalCard(festival, userEmail);
            },
          );
        },
      ),
    );
  }

  Widget _buildFestivalCard(FestivalModel festival, String? userEmail) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        festival.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(
                          DateTime.parse(festival.date),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  festival.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Time
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      festival.time,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      festival.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                // RSVP Section
                if (festival.requiresRSVP && userEmail != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('festivals')
                        .doc(festival.id)
                        .collection('rsvps')
                        .doc(userEmail)
                        .snapshots(),
                    builder: (context, rsvpSnapshot) {
                      // ✅ COMPLETELY FIXED: Proper null-safe boolean checks
                      if (rsvpSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      // Check if user has responded
                      final hasData = rsvpSnapshot.hasData;
                      final docSnapshot = rsvpSnapshot.data;
                      final hasResponded = hasData && docSnapshot != null && docSnapshot.exists;
                      
                      bool isAttending = false;
                      if (hasResponded) {
                        final data = docSnapshot.data();
                        if (data != null && data is Map<String, dynamic>) {
                          isAttending = data['attending'] ?? false;
                        }
                      }

                      if (hasResponded) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAttending ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAttending ? Colors.green.shade200 : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isAttending ? Icons.check_circle : Icons.cancel,
                                color: isAttending ? Colors.green.shade700 : Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isAttending ? 'You are attending' : 'You declined',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isAttending ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Allow changing RSVP
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Change RSVP?'),
                                      content: Text(
                                        'Do you want to ${isAttending ? "decline" : "accept"} this invitation?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _respondToRSVP(festival.id, !isAttending);
                                          },
                                          child: const Text('Confirm'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Are you attending?',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _respondToRSVP(festival.id, true),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Yes, I\'m Coming'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _respondToRSVP(festival.id, false),
                                  icon: const Icon(Icons.close),
                                  label: const Text('No, Thanks'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade400,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '${festival.attendeesCount} employee(s) attending',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
