import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../Loan_Screen/services/loan_api_service.dart';
import 'package:intl/intl.dart';

class UpcomingRemindersScreen extends StatefulWidget {
  const UpcomingRemindersScreen({super.key});

  @override
  State<UpcomingRemindersScreen> createState() => _UpcomingRemindersScreenState();
}

class _UpcomingRemindersScreenState extends State<UpcomingRemindersScreen> {
  final LoanApiService _apiService = LoanApiService();
  List<dynamic> _reminders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _apiService.fetchUpcomingReminders();
      setState(() {
        _reminders = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsDone(String id) async {
    try {
      await _apiService.markReminderDone(id);
      _loadReminders(); // Refresh list
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
            
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: brandRed),
              ))
            else if (_error != null)
              Center(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadReminders, child: const Text('Retry')),
                  ],
                ),
              ))
            else if (_reminders.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No upcoming reminders'),
              ))
            else
              ..._reminders.map((reminder) {
                final date = DateTime.parse(reminder['remindAt']);
                return ReminderCard(
                  month: DateFormat('MMM').format(date), 
                  day: DateFormat('dd').format(date), 
                  title: reminder['title'] ?? 'Reminder', 
                  dueInfo: reminder['note'] ?? 'Time: ${DateFormat.jm().format(date)}',
                  onTap: () => _markAsDone(reminder['_id']),
                );
              }),

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
