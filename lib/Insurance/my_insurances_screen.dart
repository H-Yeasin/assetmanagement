import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import 'insurance_widgets.dart';
import 'models/insurance_model.dart';
import '../services/insurance_service.dart';

class MyInsurancesScreen extends StatefulWidget {
  const MyInsurancesScreen({super.key});

  @override
  State<MyInsurancesScreen> createState() => _MyInsurancesScreenState();
}

class _MyInsurancesScreenState extends State<MyInsurancesScreen> {
  final InsuranceService _apiService = InsuranceService();
  List<InsurancePolicy> _policies = [];
  List<InsurancePolicy> _upcomingPolicies = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Personal',
    'Pet',
    'Home',
    'Auto',
    'Appliance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _apiService.fetchInsurances(),
        _apiService.fetchUpcomingRenewals(),
      ]);
      setState(() {
        _policies = results[0];
        _upcomingPolicies = results[1];
        _isLoading = false;
        debugPrint(
          'Loaded ${_policies.length} policies and ${_upcomingPolicies.length} upcoming renewals.',
        );
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $_error'), backgroundColor: brandRed),
        );
      }
    }
  }

  Future<void> _loadInsurances() async {
    await _loadData();
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _policySubtitle(InsurancePolicy policy) {
    final baseSubtitle = policy.provider ?? _titleCase(policy.category);
    if (policy.isActive) return baseSubtitle;
    return '$baseSubtitle - ${_titleCase(policy.status)}';
  }

  double _monthlyEquivalent(InsurancePolicy policy) {
    return policy.monthlyEquivalent;
  }

  double _outstandingAmount(InsurancePolicy policy) {
    if (!policy.isActive || policy.isOneTime) return 0;

    final totalPayments = policy.totalPayments ?? 0;
    final completedPayments = policy.paymentsCompleted ?? 0;

    if (totalPayments > 0) {
      final remainingPayments = totalPayments - completedPayments;
      if (remainingPayments > 0) {
        return remainingPayments * _monthlyEquivalent(policy);
      }
    }

    final freq = policy.paymentFrequency?.toLowerCase() ?? '';
    if (freq.contains('annually') || freq.contains('yearly')) {
      return policy.premium;
    }
    if (freq.contains('quarterly')) {
      return policy.premium * 3;
    }
    return policy.premium;
  }

  List<InsurancePolicy> get _activePolicies =>
      _policies.where((policy) => policy.isActive).toList();

  double get _totalMonthlyPayment {
    return _activePolicies.fold(0.0, (sum, p) => sum + _monthlyEquivalent(p));
  }

  double get _totalOutstanding {
    return _activePolicies.fold(0.0, (sum, p) => sum + _outstandingAmount(p));
  }

  List<InsurancePolicy> get _filteredPolicies {
    if (_selectedCategory == 'All') return _policies;
    return _policies
        .where(
          (p) => p.category.toLowerCase() == _selectedCategory.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: brandRed)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'My Insurances',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await context.push('/add-insurance');
                      _loadInsurances();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: brandRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInsurances,
                color: brandRed,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Summary Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE1E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Monthly Payment:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '\$${NumberFormat('#,##0.00').format(_totalMonthlyPayment)}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111111),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Total Outstanding: \$${NumberFormat('#,##0.00').format(_totalOutstanding)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Upcoming Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Upcoming Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push('/insurance-upcoming'),
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: Color(0xFF555555),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: _upcomingPolicies.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        'No upcoming actions',
                                        style: TextStyle(
                                          color: Color(0xFF888888),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                              : _upcomingPolicies.take(3).map((p) {
                                  final renewalDate =
                                      p.renewalDate ?? DateTime.now();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: UpcomingActionItem(
                                      month: DateFormat(
                                        'MMM',
                                      ).format(renewalDate),
                                      day: DateFormat('dd').format(renewalDate),
                                      title: p.name,
                                      status: p.paymentStatusLabel,
                                      amount:
                                          '\$${NumberFormat('#,##0.00').format(p.premium)}',
                                      isAutoPay: p.autoPayEnabledForStatus,
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Categories
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 24),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected = _selectedCategory == cat;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? brandRed
                                      : const Color(0xFFFBFBFB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? brandRed
                                        : const Color(0xFFF0F0F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (cat != 'All')
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Image.asset(
                                          InsurancePolicy.categoryIcon(cat),
                                          width: 18,
                                          height: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF555555),
                                          errorBuilder: (c, e, s) => Icon(
                                            Icons.category,
                                            size: 18,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF555555),
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Insurance List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: _filteredPolicies
                              .map(
                                (p) => InsuranceListItem(
                                  iconPath: InsurancePolicy.iconForCategory(
                                    p.category,
                                  ),
                                  iconBgColor:
                                      InsurancePolicy.iconBgColorForCategory(
                                        p.category,
                                      ),
                                  title: p.name,
                                  subtitle: _policySubtitle(p),
                                  amount:
                                      '\$${NumberFormat('#,##0.00').format(p.premium)}',
                                  frequency:
                                      p.paymentFrequency ??
                                      (p.isOneTime ? 'One-time' : 'Yearly'),
                                  isAutoPay: p.autoPayEnabledForStatus,
                                  onTap: () async {
                                    await context.push(
                                      '/insurance-detail',
                                      extra: p,
                                    );
                                    _loadInsurances();
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
