import 'package:flutter/material.dart';

class InsurancePolicy {
  final String? id;
  final String userId;
  final String name;
  final String category; // auto, home, pet, appliance, personal, other
  final double premium;
  final String? paymentFrequency;
  final String? provider;
  final DateTime? renewalDate;
  final String? coverageNotes;
  final List<dynamic> documents;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // These extra fields from UI will be mapped to coverageNotes JSON or specific logic
  // if the backend doesn't support them explicitly yet.
  final String? policyNumber;
  final String? coverageType;
  final String? petName;
  final String? propertyAddress;
  final String? applianceName;
  final String? manufacturer;
  
  // New Figma Fields
  final String? vehicleModel;
  final String? timeLeft;
  final int? paymentsCompleted;
  final int? totalPayments;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isAutoPay;
  final String? paymentDay;
  final String? personalInsuranceType;

  InsurancePolicy({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.premium = 0.0,
    this.paymentFrequency,
    this.provider,
    this.renewalDate,
    this.coverageNotes,
    this.documents = const [],
    this.createdAt,
    this.updatedAt,
    this.policyNumber,
    this.coverageType,
    this.petName,
    this.propertyAddress,
    this.applianceName,
    this.manufacturer,
    this.vehicleModel,
    this.timeLeft,
    this.paymentsCompleted,
    this.totalPayments,
    this.startDate,
    this.endDate,
    this.isAutoPay,
    this.paymentDay,
    this.personalInsuranceType,
  });

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    return InsurancePolicy(
      id: json['_id'],
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'other',
      premium: (json['premium'] ?? 0).toDouble(),
      paymentFrequency: json['paymentFrequency'],
      provider: json['provider'],
      renewalDate: json['renewalDate'] != null ? DateTime.parse(json['renewalDate']) : null,
      coverageNotes: json['coverageNotes'],
      documents: json['documents'] != null ? (json['documents'] as List) : [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      policyNumber: json['policyNumber'],
      coverageType: json['coverageType'],
      petName: json['petName'],
      propertyAddress: json['propertyAddress'],
      applianceName: json['applianceName'],
      manufacturer: json['manufacturer'],
      vehicleModel: json['vehicleModel'],
      timeLeft: json['timeLeft'],
      paymentsCompleted: json['paymentsCompleted'],
      totalPayments: json['totalPayments'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isAutoPay: json['isAutoPay'],
      paymentDay: json['paymentDay'],
      personalInsuranceType: json['personalInsuranceType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'premium': premium,
      'paymentFrequency': paymentFrequency,
      'provider': provider,
      'renewalDate': renewalDate?.toIso8601String(),
      'coverageNotes': coverageNotes,
      'documents': documents.map((doc) => doc is String ? doc : doc.id).toList(),
      'policyNumber': policyNumber,
      'coverageType': coverageType,
      'petName': petName,
      'propertyAddress': propertyAddress,
      'applianceName': applianceName,
      'manufacturer': manufacturer,
      'vehicleModel': vehicleModel,
      'timeLeft': timeLeft,
      'paymentsCompleted': paymentsCompleted,
      'totalPayments': totalPayments,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isAutoPay': isAutoPay,
      'paymentDay': paymentDay,
      'personalInsuranceType': personalInsuranceType,
    };
  }

  static String iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'auto':
        return 'assets/images/insurance/car.png';
      case 'home':
        return 'assets/images/insurance/farmhouse.png';
      case 'pet':
        return 'assets/images/insurance/petinsurance.png';
      case 'appliance':
        return 'assets/images/insurance/appliance.png';
      case 'personal':
        return 'assets/images/insurance/personalinsurance.png';
      default:
        return 'assets/images/insurance/car.png';
    }
  }

  static String categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'auto':
        return 'assets/images/insurance/carauto.png';
      case 'home':
        return 'assets/images/insurance/catagoryhome.png';
      case 'pet':
        return 'assets/images/insurance/catagorypet.png';
      case 'personal':
        return 'assets/images/insurance/catagorypersonal.png';
      case 'appliance':
        return 'assets/images/insurance/appliance.png';
      default:
        return 'assets/images/insurance/carauto.png';
    }
  }

  static Color colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'auto':
        return const Color(0xFFFF9800);
      case 'home':
        return const Color(0xFF2196F3);
      case 'pet':
        return const Color(0xFF4CAF50);
      case 'appliance':
        return const Color(0xFF9C27B0);
      case 'personal':
        return const Color(0xFFE91E63);
      default:
        return Colors.grey;
    }
  }

  static Color iconBgColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'auto':
        return const Color(0xFFFFF3E0);
      case 'home':
        return const Color(0xFFE3F2FD);
      case 'pet':
        return const Color(0xFFE8F5E9);
      case 'appliance':
        return const Color(0xFFF3E5F5);
      case 'personal':
        return const Color(0xFFFCE4EC);
      default:
        return const Color(0xFFF5F5F5);
    }
  }
}
