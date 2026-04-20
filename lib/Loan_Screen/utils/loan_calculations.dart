import '../models/loan_model.dart';

class LoanCalculations {
  const LoanCalculations._();

  static DateTime normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static double paymentAmount(Loan loan) => loan.monthlyPayment;

  static double monthlyEquivalent(Loan loan) {
    return monthlyEquivalentFor(
      amount: paymentAmount(loan),
      frequency: loan.paymentFrequency,
      category: loan.category,
    );
  }

  static double monthlyEquivalentFor({
    required double amount,
    required String frequency,
    String? category,
  }) {
    if (amount <= 0) return 0;
    if (category == 'mortgage') return amount;

    switch (frequency.trim().toLowerCase()) {
      case 'weekly':
        return amount * 52 / 12;
      case 'bi-weekly':
      case 'biweekly':
        return amount * 26 / 12;
      case 'monthly':
      default:
        return amount;
    }
  }

  static double estimatedRemainingBalance(Loan loan) {
    if (loan.remainingBalance > 0) {
      return loan.remainingBalance;
    }

    if (loan.totalAmount <= 0) return 0;

    final paidAmount = loan.completedPayments * paymentAmount(loan);
    final remaining = loan.totalAmount - paidAmount;
    if (remaining < 0) return 0;
    return remaining;
  }

  static int estimatedTotalPayments({
    required double totalAmount,
    required double paymentAmount,
    int enteredTotalPayments = 0,
  }) {
    if (enteredTotalPayments > 0) return enteredTotalPayments;
    if (totalAmount <= 0 || paymentAmount <= 0) return 0;
    return (totalAmount / paymentAmount).ceil();
  }

  static DateTime nextDueDate(
    DateTime? baseDate,
    String frequency, {
    DateTime? from,
  }) {
    final start = normalizeDay(baseDate ?? from ?? DateTime.now());
    final reference = normalizeDay(from ?? DateTime.now());
    if (!start.isBefore(reference)) return start;

    final normalizedFrequency = frequency.trim().toLowerCase();
    if (normalizedFrequency == 'weekly' ||
        normalizedFrequency == 'bi-weekly' ||
        normalizedFrequency == 'biweekly') {
      final days = normalizedFrequency == 'weekly' ? 7 : 14;
      final diffDays = reference.difference(start).inDays;
      final periods = (diffDays / days).ceil();
      return start.add(Duration(days: periods * days));
    }

    var next = start;
    while (next.isBefore(reference)) {
      next = _addMonths(next, 1);
    }
    return next;
  }

  static DateTime nextDueDateAfter(DateTime date, String frequency) {
    final normalizedFrequency = frequency.trim().toLowerCase();
    if (normalizedFrequency == 'weekly') {
      return normalizeDay(date).add(const Duration(days: 7));
    }
    if (normalizedFrequency == 'bi-weekly' ||
        normalizedFrequency == 'biweekly') {
      return normalizeDay(date).add(const Duration(days: 14));
    }
    return _addMonths(normalizeDay(date), 1);
  }

  static String amountFrequencyLabel(Loan loan) {
    final frequency = loan.paymentFrequency.trim().isEmpty
        ? 'Monthly'
        : loan.paymentFrequency;
    return frequency == 'Monthly' ? 'Monthly' : frequency;
  }

  static DateTime _addMonths(DateTime date, int months) {
    final targetMonth = date.month + months;
    final targetYear = date.year + ((targetMonth - 1) ~/ 12);
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final day = date.day;
    final lastDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
    return DateTime(targetYear, normalizedMonth, day > lastDay ? lastDay : day);
  }
}
