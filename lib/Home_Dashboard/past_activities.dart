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
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFC61C36)))
              : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadActivities,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _activityGroups.isEmpty
                  ? const Center(child: Text('No past activities found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      itemCount: _activityGroups.length,
                      itemBuilder: (context, index) {
                        final group = _activityGroups[index];
                        final date = DateTime.parse(group['date']);
                        final items = group['items'] as List;
                        
                        return Column(
                          children: items.map((item) {
                            return PaymentCard(
                              month: DateFormat('MMM').format(date), 
                              day: DateFormat('dd').format(date), 
                              title: item['name'] ?? 'Loan Payment', 
                              amount: '\$${(item['monthlyPayment'] ?? 0).toStringAsFixed(2)}', 
                              status: 'Paid', 
                              isPaid: true,
                            );
                          }).toList(),
                        );
                      },
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
