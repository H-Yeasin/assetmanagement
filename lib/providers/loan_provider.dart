import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ffp_vault/Loan_Screen/models/loan_model.dart';
// Note: We'll inject Hive directly here later when the model is adapted for HiveType.

class LoanNotifier extends StateNotifier<List<Loan>> {
  LoanNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    // Scaffold for loading loans from Hive
    // final box = await Hive.openBox<Loan>('loansBox');
    // state = box.values.toList();
  }

  Future<void> addLoan(Loan loan) async {
    // final box = await Hive.openBox<Loan>('loansBox');
    // await box.put(loan.id, loan);
    state = [...state, loan];
  }
}

final loanProvider = StateNotifierProvider<LoanNotifier, List<Loan>>((ref) {
  return LoanNotifier();
});
