import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../Insurance/models/insurance_model.dart';
import '../Loan_Screen/models/document_model.dart';

class InsuranceOccurrence {
  final InsurancePolicy policy;
  final DateTime date;

  const InsuranceOccurrence({required this.policy, required this.date});
}

class InsuranceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ffpvault',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Insurance Policies ──────────────────────────────────────────────────────

  Future<List<InsurancePolicy>> fetchInsurances({
    String? category,
    String? status,
  }) async {
    if (_uid == null) return [];

    Query query = _firestore
        .collection('insurancePolicies')
        .where('userId', isEqualTo: _uid);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    final policies = snapshot.docs
        .map(
          (doc) => InsurancePolicy.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          }),
        )
        .toList();

    if (status == null) return policies;

    final normalizedStatus = status.toLowerCase();
    return policies
        .where((policy) => policy.normalizedStatus == normalizedStatus)
        .toList();
  }

  Stream<List<InsurancePolicy>> streamInsurances({
    String? category,
    String? status,
  }) {
    if (_uid == null) return Stream.value([]);

    Query query = _firestore
        .collection('insurancePolicies')
        .where('userId', isEqualTo: _uid);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      final policies = snapshot.docs
          .map(
            (doc) => InsurancePolicy.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      if (status == null) return policies;

      final normalizedStatus = status.toLowerCase();
      return policies
          .where((policy) => policy.normalizedStatus == normalizedStatus)
          .toList();
    });
  }

  Future<InsurancePolicy> getInsurance(String id) async {
    final doc = await _firestore.collection('insurancePolicies').doc(id).get();
    if (!doc.exists) throw Exception('Insurance policy not found');
    return InsurancePolicy.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<InsurancePolicy> createInsurance(InsurancePolicy policy) async {
    if (_uid == null) throw Exception('User not logged in');

    final data = policy.toJson();
    data['userId'] = _uid;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    final docRef = await _firestore.collection('insurancePolicies').add(data);
    final doc = await docRef.get();
    return InsurancePolicy.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<InsurancePolicy> updateInsurance(
    String id,
    Map<String, dynamic> updates,
  ) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('insurancePolicies').doc(id).update(updates);
    return getInsurance(id);
  }

  Future<void> deleteInsurance(String id) async {
    await _firestore.collection('insurancePolicies').doc(id).delete();
  }

  Future<List<InsurancePolicy>> fetchUpcomingRenewals({
    DateTime? from,
    DateTime? to,
  }) async {
    final occurrences = await fetchUpcomingRenewalOccurrences(
      from: from,
      to: to,
    );
    final seenIds = <String>{};
    final policies = <InsurancePolicy>[];
    for (final occurrence in occurrences) {
      final id = occurrence.policy.id ?? occurrence.policy.name;
      if (seenIds.add(id)) {
        policies.add(occurrence.policy);
      }
    }
    return policies;
  }

  Future<List<InsuranceOccurrence>> fetchUpcomingRenewalOccurrences({
    DateTime? from,
    DateTime? to,
  }) async {
    if (_uid == null) return [];

    final effectiveFrom = _normalizeDay(from ?? DateTime.now());
    final effectiveTo = to == null ? null : _normalizeDay(to);

    final policies = await fetchInsurances(status: 'active');
    final occurrences = <InsuranceOccurrence>[];

    for (final policy in policies) {
      final dates = generateOccurrences(policy, from: from, to: to);
      for (final date in dates) {
        final day = _normalizeDay(date);
        if (day.isBefore(effectiveFrom)) continue;
        if (effectiveTo != null && day.isAfter(effectiveTo)) continue;
        occurrences.add(InsuranceOccurrence(policy: policy, date: day));
      }
    }

    occurrences.sort((a, b) => a.date.compareTo(b.date));
    return occurrences;
  }

  static List<DateTime> generateOccurrences(
    InsurancePolicy policy, {
    DateTime? from,
    DateTime? to,
  }) {
    if (!policy.isActive) return [];

    final effectiveFrom = _normalizeDay(from ?? DateTime.now());
    final effectiveTo = _normalizeDay(to ?? _addMonths(effectiveFrom, 6));

    if (policy.isOneTime) {
      final oneTimeDate =
          policy.renewalDate ?? policy.endDate ?? policy.startDate;
      if (oneTimeDate == null) return [];
      final day = _normalizeDay(oneTimeDate);
      if (day.isBefore(effectiveFrom) || day.isAfter(effectiveTo)) return [];
      return [day];
    }

    final baseDate = policy.startDate ?? policy.renewalDate;
    if (baseDate == null) return [];

    final policyEndDate = policy.endDate == null
        ? effectiveTo
        : _normalizeDay(policy.endDate!);
    final cutoff = policyEndDate.isBefore(effectiveTo)
        ? policyEndDate
        : effectiveTo;
    if (cutoff.isBefore(effectiveFrom)) return [];

    final dates = <DateTime>[];
    var next = _nextDueDate(
      baseDate,
      policy.normalizedFrequency,
      effectiveFrom,
    );
    var guard = 0;
    while (!next.isAfter(cutoff) && guard < 400) {
      dates.add(next);
      next = _nextDueDateAfter(next, policy.normalizedFrequency);
      guard++;
    }
    return dates;
  }

  // ── Documents ─────────────────────────────────────────────────────────────

  Future<DocumentFile> uploadDocument(
    File file, {
    String module = 'insurance',
    String? folderId,
    String? relatedType,
    String? relatedId,
    String? displayName,
  }) async {
    if (_uid == null) throw Exception('User not logged in');

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final contentType = _getMimeType(file.path);
    final ref = _storage.ref().child('$module/$_uid/$fileName');

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );
    await uploadTask.whenComplete(() => null);
    final downloadUrl = await ref.getDownloadURL();

    final Map<String, dynamic> docData = <String, dynamic>{
      'userId': _uid!,
      'module': module,
      'originalName': file.path.split('/').last,
      'displayName': displayName ?? file.path.split('/').last,
      'filename': fileName,
      'mimeType': _getMimeType(file.path),
      'size': await file.length(),
      'path': downloadUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (relatedType != null) docData['relatedType'] = relatedType;
    if (relatedId != null) docData['relatedId'] = relatedId;
    if (folderId != null) docData['folderId'] = folderId;

    final docRef = await _firestore.collection('documents').add(docData);

    /*
    if (relatedType == 'insurance' && relatedId != null) {
      final Map<String, Object> updateData = <String, Object>{
        'documents': FieldValue.arrayUnion(<String>[docRef.id]),
      };
      await _firestore
          .collection('insurancePolicies')
          .doc(relatedId)
          .update(updateData);
    }
*/

    final docSnapshot = await docRef.get();
    final Map<String, dynamic> finalData = Map<String, dynamic>.from(
      docSnapshot.data()!,
    );
    finalData['id'] = docRef.id;
    return DocumentFile.fromJson(finalData);
  }

  Future<List<DocumentFile>> fetchDocumentsByModule(String module) async {
    if (_uid == null) return [];
    final snapshot = await _firestore
        .collection('documents')
        .where('userId', isEqualTo: _uid)
        .where('module', isEqualTo: module)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => DocumentFile.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<DocumentFile>> fetchDocumentsByRelated(
    String relatedId,
    String relatedType,
  ) async {
    if (_uid == null) return [];
    final snapshot = await _firestore
        .collection('documents')
        .where('userId', isEqualTo: _uid)
        .where('relatedId', isEqualTo: relatedId)
        .where('relatedType', isEqualTo: relatedType)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => DocumentFile.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> deleteDocument(String id) async {
    final doc = await _firestore.collection('documents').doc(id).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null &&
          data['mimeType'] != 'application/vnd.anick-giroux.folder' &&
          _uid != null &&
          data['module'] != null &&
          data['filename'] != null) {
        try {
          await _storage
              .ref()
              .child('${data['module']}/$_uid/${data['filename']}')
              .delete();
        } catch (e) {
          debugPrint('Storage deletion failed or file already deleted: $e');
        }
      }
      try {
        await _firestore.collection('documents').doc(id).delete();
      } catch (e) {
        debugPrint('Firestore deletion failed: $e');
      }
    }
  }

  Future<void> renameDocument(String id, String newName) async {
    await _firestore.collection('documents').doc(id).update({
      'displayName': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Reminders ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createReminder({
    required String itemType,
    required String itemId,
    required DateTime remindAt,
    String? title,
    String? note,
  }) async {
    if (_uid == null) throw Exception('User not logged in');

    final data = {
      'userId': _uid,
      'itemType': itemType,
      'itemId': itemId,
      'remindAt': Timestamp.fromDate(remindAt),
      'title': title,
      'note': note,
      'isDone': false,
      'notificationEnabled': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final existing = await _firestore
        .collection('reminders')
        .where('userId', isEqualTo: _uid)
        .where('itemType', isEqualTo: itemType)
        .where('itemId', isEqualTo: itemId)
        .where('isDone', isEqualTo: false)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final docRef = existing.docs.first.reference;
      await docRef.update({...data, 'updatedAt': FieldValue.serverTimestamp()});
      final doc = await docRef.get();
      return {...doc.data()!, 'id': doc.id};
    }

    final docRef = await _firestore.collection('reminders').add(data);
    final doc = await docRef.get();
    return {...doc.data()!, 'id': doc.id};
  }

  Future<void> updateReminderNotificationEnabled(
    String id,
    bool enabled,
  ) async {
    await _firestore.collection('reminders').doc(id).update({
      'notificationEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<dynamic>> fetchUpcomingReminders({
    DateTime? from,
    DateTime? to,
  }) async {
    if (_uid == null) return [];

    Query query = _firestore
        .collection('reminders')
        .where('userId', isEqualTo: _uid)
        .where('isDone', isEqualTo: false);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
        .toList();
  }

  Stream<int> streamDocumentsCountForRelated(String relatedId) {
    if (_uid == null) return Stream.value(0);
    return _firestore
        .collection('documents')
        .where('userId', isEqualTo: _uid)
        .where('relatedId', isEqualTo: relatedId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  static DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _nextDueDate(
    DateTime baseDate,
    String frequency,
    DateTime from,
  ) {
    final start = _normalizeDay(baseDate);
    final reference = _normalizeDay(from);
    if (!start.isBefore(reference)) return start;

    final normalizedFrequency = frequency.trim().toLowerCase();
    if (normalizedFrequency.contains('weekly') ||
        normalizedFrequency.contains('bi-weekly') ||
        normalizedFrequency.contains('biweekly')) {
      final days =
          normalizedFrequency.contains('bi-weekly') ||
              normalizedFrequency.contains('biweekly')
          ? 14
          : 7;
      final diffDays = reference.difference(start).inDays;
      final periods = (diffDays / days).ceil();
      return start.add(Duration(days: periods * days));
    }

    final months = normalizedFrequency.contains('quarterly')
        ? 3
        : normalizedFrequency.contains('annually') ||
              normalizedFrequency.contains('yearly')
        ? 12
        : 1;
    var next = start;
    while (next.isBefore(reference)) {
      next = _addMonths(next, months);
    }
    return next;
  }

  static DateTime _nextDueDateAfter(DateTime date, String frequency) {
    final normalizedFrequency = frequency.trim().toLowerCase();
    if (normalizedFrequency.contains('bi-weekly') ||
        normalizedFrequency.contains('biweekly')) {
      return _normalizeDay(date).add(const Duration(days: 14));
    }
    if (normalizedFrequency.contains('weekly')) {
      return _normalizeDay(date).add(const Duration(days: 7));
    }
    if (normalizedFrequency.contains('quarterly')) {
      return _addMonths(_normalizeDay(date), 3);
    }
    if (normalizedFrequency.contains('annually') ||
        normalizedFrequency.contains('yearly')) {
      return _addMonths(_normalizeDay(date), 12);
    }
    return _addMonths(_normalizeDay(date), 1);
  }

  static DateTime _addMonths(DateTime date, int months) {
    final targetMonth = date.month + months;
    final targetYear = date.year + ((targetMonth - 1) ~/ 12);
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final lastDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(targetYear, normalizedMonth, day);
  }
}
