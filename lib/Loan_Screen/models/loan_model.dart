import 'dart:convert';
import 'package:hive/hive.dart';
import 'document_model.dart';

part 'loan_model.g.dart';

@HiveType(typeId: 0)
class Loan extends HiveObject {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final double monthlyPayment;
  @HiveField(5)
  final DateTime? paymentDate;
  @HiveField(6)
  final bool autoPay;
  @HiveField(7)
  final double totalAmount;
  @HiveField(8)
  final double interestRate;
  @HiveField(9)
  final DateTime? startDate;
  @HiveField(10)
  final DateTime? endDate;
  @HiveField(11)
  final double remainingBalance;
  @HiveField(12)
  final String? lender;
  @HiveField(13)
  final String? notes;
  @HiveField(14)
  final String status;
  @HiveField(15)
  final DateTime? completedAt;
  @HiveField(16)
  final List<dynamic> documents;
  @HiveField(17)
  final DateTime? createdAt;
  @HiveField(18)
  final DateTime? updatedAt;

  // New fields for Figma parity
  @HiveField(19)
  final String? propertyAddress;
  @HiveField(20)
  final String? apartmentName;
  @HiveField(21)
  final String? amortizationPeriod;
  @HiveField(22)
  final int totalPayments;
  @HiveField(23)
  final int completedPayments;

  Loan({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.monthlyPayment = 0.0,
    this.paymentDate,
    this.autoPay = false,
    this.totalAmount = 0.0,
    this.interestRate = 0.0,
    this.startDate,
    this.endDate,
    this.remainingBalance = 0.0,
    this.lender,
    this.notes,
    this.status = 'active',
    this.completedAt,
    this.documents = const [],
    this.createdAt,
    this.updatedAt,
    this.propertyAddress,
    this.apartmentName,
    this.amortizationPeriod,
    this.totalPayments = 0,
    this.completedPayments = 0,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['_id'],
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'other',
      monthlyPayment: (json['monthlyPayment'] ?? 0).toDouble(),
      paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : null,
      autoPay: json['autoPay'] ?? false,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      interestRate: (json['interestRate'] ?? 0).toDouble(),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      remainingBalance: (json['remainingBalance'] ?? 0).toDouble(),
      lender: json['lender'],
      notes: json['notes'],
      status: json['status'] ?? 'active',
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      documents: json['documents'] != null 
          ? (json['documents'] as List).map((doc) => doc is String ? doc : DocumentFile.fromJson(doc)).toList() 
          : [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      propertyAddress: json['propertyAddress'],
      apartmentName: json['apartmentName'],
      amortizationPeriod: json['amortizationPeriod'],
      totalPayments: json['totalPayments'] ?? 0,
      completedPayments: json['completedPayments'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'monthlyPayment': monthlyPayment,
      'paymentDate': paymentDate?.toIso8601String(),
      'autoPay': autoPay,
      'totalAmount': totalAmount,
      'interestRate': interestRate,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'remainingBalance': remainingBalance,
      'lender': lender,
      'notes': notes,
      'status': status,
      'propertyAddress': propertyAddress,
      'apartmentName': apartmentName,
      'amortizationPeriod': amortizationPeriod,
      'totalPayments': totalPayments,
      'completedPayments': completedPayments,
      'documents': documents.map((doc) => doc is String ? doc : (doc as DocumentFile).id).toList(),
    };
  }
}
