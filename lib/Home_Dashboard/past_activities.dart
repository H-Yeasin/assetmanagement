import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets.dart';
import '../Loan_Screen/services/loan_api_service.dart';

class PastActivitiesScreen extends StatefulWidget {
  const PastActivitiesScreen({super.key});

  @override
  State<PastActivitiesScreen> createState() => _PastActivitiesScreenState();
}

class _PastActivitiesScreenState extends State<PastActivitiesScreen> {
  final LoanApiService _apiService = LoanApiService();
  List<dynamic> _activityGroups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final groups = await _apiService.fetchPastActivities();
      setState(() {
        _activityGroups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          'View Past Activities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: const [
                PaymentCard(
                  month: 'Sept',
                  day: '22',
                  title: 'Student Loan',
                  amount: '\$1,300.00',
                  status: 'Paid',
                  isPaid: true,
                ),
                PaymentCard(
                  month: 'Sept',
                  day: '17',
                  title: 'Car Loan',
                  amount: '\$2,230.00',
                  status: 'Manual payment required',
                  isPaid: false,
                ),
              ],
            ),
          ),

          // Data Deletion Notice
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'All data will be deleted within 14 days.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFBBBBBB),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
