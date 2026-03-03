import 'package:flutter/material.dart';
import '../Home_Dashboard/widgets.dart';
import 'loan_widgets.dart';
import 'models/loan_model.dart';
import 'services/loan_api_service.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({super.key});

  @override
  State<MyLoansScreen> createState() => _MyLoansScreenState();
}

class _MyLoansScreenState extends State<MyLoansScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['All Loans', 'Active', 'Completed'];

  final LoanApiService _apiService = LoanApiService();
  List<Loan> _allLoans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final loans = await _apiService.fetchLoans();
      setState(() {
        _allLoans = loans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Loan> get _filteredLoans {
    if (_selectedTab == 0) return _allLoans;
    if (_selectedTab == 1)
      return _allLoans.where((l) => l.status == 'active').toList();
    if (_selectedTab == 2)
      return _allLoans.where((l) => l.status == 'completed').toList();
    return _allLoans;
  }

  double get _totalMonthlyPayment {
    return _allLoans
        .where((l) => l.status == 'active')
        .fold(0.0, (sum, l) => sum + l.monthlyPayment);
  }

  double get _totalOutstanding {
    return _allLoans
        .where((l) => l.status == 'active')
        .fold(0.0, (sum, l) => sum + l.remainingBalance);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: brandRed)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: const TextStyle(color: brandRed)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadLoans, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFFBFBFB,
      ), // Very slight off-white background
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
                      'My Loans',
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
                      final result = await context.push<bool>('/add-loan');
                      if (result == true) {
                        _loadLoans();
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: brandRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Summary Card ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF0F0F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Monthly Payment:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF888888),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              // Format without currency symbol
                              NumberFormat(
                                '#,##0.00',
                              ).format(_totalMonthlyPayment),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Total Outstanding: ${NumberFormat.simpleCurrency().format(_totalOutstanding)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Upcoming Actions Header ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Upcoming Actions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF888888),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.push('/upcoming-actions');
                            },
                            child: const Text(
                              'See All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Payment Cards ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FutureBuilder<List<dynamic>>(
                        future: _apiService.fetchUpcomingPayments(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: brandRed,
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(
                                  color: brandRed,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No upcoming actions',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }

                          // Get first 3 items across all date groups
                          final allItems = <Map<String, dynamic>>[];
                          for (var group in snapshot.data!) {
                            final date = DateTime.parse(group['date']);
                            for (var item in group['items']) {
                              allItems.add({'date': date, 'item': item});
                            }
                          }

                          final displayItems = allItems.take(3).toList();

                          return Column(
                            children: displayItems.map((data) {
                              final date = data['date'] as DateTime;
                              final item = data['item'];
                              return PaymentCard(
                                month: DateFormat('MMM').format(date),
                                day: DateFormat('dd').format(date),
                                title: item['name'],
                                amount: NumberFormat.simpleCurrency().format(
                                  item['monthlyPayment'],
                                ),
                                status: item['autoPay']
                                    ? 'Paid automatically'
                                    : 'Manual payment required',
                                isPaid: item['autoPay'],
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Tab Bar ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: List.generate(_tabs.length, (index) {
                          final isSelected = _selectedTab == index;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index < _tabs.length - 1 ? 12.0 : 0.0,
                              ),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedTab = index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected ? brandRed : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: const Color(0xFFEEEEEE),
                                          ),
                                    boxShadow: isSelected
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _tabs[index],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF777777),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Active Loans Label ──
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'ACTIVE LOANS',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Loans List ──
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: brandRed),
                        ),
                      )
                    else if (_error != null)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Error: $_error',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (_filteredLoans.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No loans found',
                            style: TextStyle(color: Color(0xFF888888)),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: _filteredLoans.map((loan) {
                            String iconPath =
                                'assets/images/icon/custom_loan.png';
                            if (loan.category.toLowerCase().contains('home') ||
                                loan.category.toLowerCase().contains(
                                  'mortgage',
                                )) {
                              iconPath =
                                  'assets/images/icon/home_morgarate.png'; // Make sure actual asset exists, using your provided logic
                            } else if (loan.category.toLowerCase().contains(
                              'car',
                            )) {
                              iconPath = 'assets/images/icon/car_loan.png';
                            } else if (loan.category.toLowerCase().contains(
                              'student',
                            )) {
                              iconPath = 'assets/images/icon/student_loan.png';
                            } else if (loan.category.toLowerCase().contains(
                              'personal',
                            )) {
                              iconPath = 'assets/images/icon/personal_loan.png';
                            }

                            return LoanListItem(
                              iconPath: iconPath,
                              title: loan.name,
                              subtitle: loan.lender ?? '',
                              // Format amounts to look like $420,000 without decimal zeroes if whole.
                              amount: NumberFormat.simpleCurrency(
                                decimalDigits: loan.totalAmount % 1 == 0
                                    ? 0
                                    : 2,
                              ).format(loan.totalAmount),
                              status: loan.autoPay
                                  ? 'Paid automatically'
                                  : 'Manual payment required',
                              isPaid: loan.autoPay,
                              onTap: () async {
                                final result = await context.push<bool>(
                                  '/loan-detail',
                                  extra: loan,
                                );
                                if (result == true) {
                                  _loadLoans();
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── View Completed Loans ──
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/completed-loans');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history,
                              color: brandRed,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'View Completed Loans',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: brandRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
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
