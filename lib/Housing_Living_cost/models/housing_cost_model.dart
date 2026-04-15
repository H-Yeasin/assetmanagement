import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

class HousingCost {
  final String? id;
  final String userId;
  final String name;
  final String category;
  final double amount;
  final DateTime? dueDate;
  final bool autoPay;
  final String? notes;
  final List<dynamic> documents;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HousingCost({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.amount = 0.0,
    this.dueDate,
    this.autoPay = false,
    this.notes,
    this.documents = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory HousingCost.fromJson(Map<String, dynamic> json) {
    return HousingCost(
      id: json['id'] ?? json['_id'],
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'other',
      amount: (json['amount'] ?? 0).toDouble(),
      dueDate: _parseDate(json['dueDate']),
      autoPay: json['autoPay'] ?? false,
      notes: json['notes'],
      documents: json['documents'] != null ? (json['documents'] as List) : [],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    // Handle Map structure often found in server-side logs or certain SDK versions
    if (value is Map && value.containsKey('_seconds')) {
      return Timestamp(value['_seconds'] as int, value['_nanoseconds'] as int).toDate();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'amount': amount,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'autoPay': autoPay,
      'notes': notes,
      'documents': documents
          .map((doc) => doc is String ? doc : doc.id)
          .toList(),
    };
  }

  /// Returns the icon path for this category
  static String iconForCategory(String category) {
    switch (category) {
      case 'housing':
        return 'assets/images/icon/home_morgarate.png';
      case 'utilities':
        return 'assets/images/icon/gas_bill.png';
      case 'transportation':
        return 'assets/images/icon/transport_bill.png';
      case 'groceries':
        return 'assets/images/icon/other_services.png';
      case 'internet':
        return 'assets/images/icon/wifi_bill.png';
      case 'phone':
        return 'assets/images/icon/wifi_bill.png';
      case 'insurance':
        return 'assets/images/icon/insurance.png';
      case 'maintenance':
        return 'assets/images/icon/other_services.png';
      case 'other':
      default:
        return 'assets/images/icon/other_services.png';
    }
  }

  /// Maps Figma display categories to backend categories
  static const List<Map<String, String>> displayCategories = [
    {
      'id': 'housing',
      'label': 'Housing',
      'icon': 'assets/images/icon/home_morgarate.png',
    },
    {
      'id': 'utilities',
      'label': 'Utilities',
      'icon': 'assets/images/icon/gas_bill.png',
    },
    {
      'id': 'internet',
      'label': 'Connectivity',
      'icon': 'assets/images/icon/wifi_bill.png',
    },
    {
      'id': 'transportation',
      'label': 'Transportation',
      'icon': 'assets/images/icon/transport_bill.png',
    },
    {
      'id': 'insurance',
      'label': 'Credit & Revolving',
      'icon': 'assets/images/icon/cradit_resolving.png',
    },
    {
      'id': 'maintenance',
      'label': 'Family & Personal',
      'icon': 'assets/images/icon/family_personal.png',
    },
    {
      'id': 'other',
      'label': 'Other Services',
      'icon': 'assets/images/icon/other_services.png',
    },
  ];

  /// Background color for the icon circle
  static Color iconBgColorForCategory(String category) {
    switch (category) {
      case 'housing':
        return const Color(0xFFE3F2FD); // Light blue
      case 'utilities':
        return const Color(0xFFFFF9C4); // Light yellow
      case 'internet':
        return const Color(0xFFE8F5E9); // Light green
      case 'transportation':
        return const Color(0xFFE8EAF6); // Light indigo
      case 'insurance':
        return const Color(0xFFFFF3E0); // Light orange
      case 'maintenance':
        return const Color(0xFFF3E5F5); // Light purple
      case 'groceries':
        return const Color(0xFFFFEBEE); // Light red
      case 'phone':
        return const Color(0xFFE0F7FA); // Light cyan
      case 'other':
      default:
        return const Color(0xFFFFEBEE); // Light red
    }
  }
}
