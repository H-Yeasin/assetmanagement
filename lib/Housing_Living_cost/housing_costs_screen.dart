import 'package:flutter/material.dart';
import '../Home_Dashboard/widgets.dart';
import 'housing_widgets.dart';
import 'add_housing_cost_screen.dart';
import 'housing_cost_detail_screen.dart';
import 'models/housing_cost_model.dart';
import '../services/housing_service.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class HousingCostsScreen extends StatefulWidget {
  const HousingCostsScreen({super.key});

  @override
  State<HousingCostsScreen> createState() => _HousingCostsScreenState();
}

class _HousingCostsScreenState extends State<HousingCostsScreen> {
  final HousingService _apiService = HousingService();
  List<HousingCost> _costs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCosts();
  }

  Future<void> _loadCosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final costs = await _apiService.fetchHousingCosts();
      setState(() {
        _costs = costs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _totalMonthlyPayment {
    return _costs.fold(0.0, (sum, c) => sum + c.amount);
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
              ElevatedButton(onPressed: _loadCosts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
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
                      'Housing/Living Costs',
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
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddHousingCostScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadCosts();
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
                              '\$ ${NumberFormat('#,##0.00').format(_totalMonthlyPayment)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Costs List ──
                    if (_costs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No housing costs found',
                            style: TextStyle(color: Color(0xFF888888)),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: _costs.map((cost) {
                            final iconPath = HousingCost.iconForCategory(
                              cost.category,
                            );
                            final iconBgColor =
                                HousingCost.iconBgColorForCategory(
                                  cost.category,
                                );
                            final catInfo = HousingCost.displayCategories
                                .firstWhere(
                                  (c) => c['id'] == cost.category,
                                  orElse: () => {'label': cost.category},
                                );

                            String formattedDate = '';
                            if (cost.dueDate != null) {
                              formattedDate = ' • Due ${DateFormat('MMM dd').format(cost.dueDate!)}';
                            }
                            final subtitleText = '${catInfo['label'] ?? cost.category}$formattedDate';

                            return HousingCostListItem(
                              iconPath: iconPath,
                              iconBgColor: iconBgColor,
                              title: cost.name,
                              subtitle: subtitleText,
                              amount: '\$${NumberFormat('#,##0.00').format(cost.amount)}',
                              status: cost.autoPay
                                  ? 'Auto Payment'
                                  : 'Manual payment required',
                              isPaid: cost.autoPay,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HousingCostDetailScreen(cost: cost),
                                  ),
                                );
                                if (result == true) {
                                  _loadCosts();
                                }
                              },
                            );
                          }).toList(),
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
    ));
  }
}
