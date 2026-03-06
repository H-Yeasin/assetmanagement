import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/loan_service.dart';
import 'package:intl/intl.dart';

class UpcomingRemindersScreen extends StatefulWidget {
  const UpcomingRemindersScreen({super.key});

  @override
  State<UpcomingRemindersScreen> createState() =>
      _UpcomingRemindersScreenState();
}

class _UpcomingRemindersScreenState extends State<UpcomingRemindersScreen> {
  final LoanService _loanService = LoanService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _markAsDone(String id) async {
    try {
      await _loanService.markReminderDone(id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark reminder as done: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upcoming Reminders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment List Section
            const Text(
              'Upcoming',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 20),

            StreamBuilder<List<dynamic>>(
              stream: _loanService.streamUpcomingReminders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: brandRed));
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: brandRed));
                }
                
                final reminders = snapshot.data ?? [];
                if (reminders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No upcoming reminders.', style: TextStyle(color: Colors.grey)),
                  );
                }

                return Column(
                  children: reminders.map<Widget>((r) {
                    final remindAt = (r['remindAt'] as dynamic).toDate() as DateTime;
                    final note = r['note'] ?? r['title'] ?? 'Reminder';
                    final title = r['title'] ?? 'Task';
                    return ReminderCard(
                      month: DateFormat('MMM').format(remindAt),
                      day: DateFormat('dd').format(remindAt),
                      title: title,
                      dueInfo: note,
                      onTap: () {
                        // could show details, or a dialog to mark as done
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(title),
                            content: Text(note),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _markAsDone(r['id']);
                                },
                                child: const Text('Mark Done'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // View Past Activity Button
            Center(
              child: GestureDetector(
                onTap: () {
                  context.push('/past-activities');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.history, size: 18, color: brandRed),
                    SizedBox(width: 8),
                    Text(
                      'View Past Activity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: brandRed,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
