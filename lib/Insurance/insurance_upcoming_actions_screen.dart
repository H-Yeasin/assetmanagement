import 'package:flutter/material.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/insurance_service.dart';
import 'models/insurance_model.dart';
import 'package:ffp_vault/Insurance/insurance_widgets.dart';
import 'package:intl/intl.dart';

class InsuranceUpcomingActionsScreen extends StatefulWidget {
  const InsuranceUpcomingActionsScreen({super.key});

  @override
  State<InsuranceUpcomingActionsScreen> createState() =>
      _InsuranceUpcomingActionsScreenState();
}

class _InsuranceUpcomingActionsScreenState
    extends State<InsuranceUpcomingActionsScreen> {
  final InsuranceService _apiService = InsuranceService();
  List<InsurancePolicy> _upcomingPolicies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUpcoming();
  }

  Future<void> _loadUpcoming() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final policies = await _apiService.fetchUpcomingRenewals();
      setState(() {
        _upcomingPolicies = policies;
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
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF111111),
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upcoming Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Edit',
              style: TextStyle(
                color: brandRed,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandRed))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: $_error', textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUpcoming,
              color: brandRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Actions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Text(
                        //   'See All',
                        //   style: TextStyle(
                        //     fontSize: 14,
                        //     color: Color(0xFF111111),
                        //     fontWeight: FontWeight.w700,
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_upcomingPolicies.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text(
                            'No upcoming actions',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._upcomingPolicies.map((p) {
                        final renewalDate = p.renewalDate ?? DateTime.now();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: UpcomingActionItem(
                            month: DateFormat('MMM').format(renewalDate),
                            day: DateFormat('dd').format(renewalDate),
                            title: p.name,
                            status:
                                p.paymentFrequency?.toLowerCase() == 'manual'
                                ? 'Manual payment required'
                                : 'Paid automatically',
                            amount:
                                '\$${NumberFormat('#,##0.00').format(p.premium)}',
                            isAutoPay:
                                p.paymentFrequency?.toLowerCase() != 'manual',
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}
