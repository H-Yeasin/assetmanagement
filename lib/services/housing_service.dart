import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../Housing_Living_cost/models/housing_cost_model.dart';
import '../Loan_Screen/models/document_model.dart';

class HousingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ffpvault',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Housing Costs ───────────────────────────────────────────────────────────

  Future<List<HousingCost>> fetchHousingCosts({String? category}) async {
    if (_uid == null) return [];

    Query query = _firestore
        .collection('housingCosts')
        .where('userId', isEqualTo: _uid);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => HousingCost.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          }),
        )
        .toList();
  }

  Stream<List<HousingCost>> streamHousingCosts({String? category}) {
    if (_uid == null) return Stream.value([]);

    Query query = _firestore
        .collection('housingCosts')
        .where('userId', isEqualTo: _uid);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => HousingCost.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList(),
    );
  }

  Future<HousingCost> getHousingCost(String id) async {
    final doc = await _firestore.collection('housingCosts').doc(id).get();
    if (!doc.exists) throw Exception('Housing cost not found');
    return HousingCost.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<HousingCost> createHousingCost(HousingCost cost) async {
    if (_uid == null) throw Exception('User not logged in');

    final data = cost.toJson();
    data['userId'] = _uid;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    final docRef = await _firestore.collection('housingCosts').add(data);
    final doc = await docRef.get();
    return HousingCost.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<HousingCost> updateHousingCost(
    String id,
    Map<String, dynamic> updates,
  ) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('housingCosts').doc(id).update(updates);
    return getHousingCost(id);
  }

  Future<void> deleteHousingCost(String id) async {
    await _firestore.collection('housingCosts').doc(id).delete();
  }

  Future<List<HousingCost>> fetchUpcomingHousingCosts({
    DateTime? from,
    DateTime? to,
  }) async {
    if (_uid == null) return [];

    final now = DateTime.now();
    final start = from ?? now;
    final end = to ?? DateTime(now.year, now.month + 1, now.day);

    Query query = _firestore
        .collection('housingCosts')
        .where('userId', isEqualTo: _uid)
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('dueDate');

    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => HousingCost.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          }),
        )
        .toList();
  }

  // ── Documents ─────────────────────────────────────────────────────────────

  Future<DocumentFile> uploadDocument(
    File file, {
    String module = 'housing',
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
    if (relatedType == 'housing' && relatedId != null) {
      final Map<String, Object> updateData = <String, Object>{
        'documents': FieldValue.arrayUnion(<String>[docRef.id]),
      };
      await _firestore
          .collection('housingCosts')
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

  Stream<int> streamDocumentsCountForRelated(String relatedId) {
    if (_uid == null) return Stream.value(0);
    return _firestore
        .collection('documents')
        .where('userId', isEqualTo: _uid)
        .where('relatedId', isEqualTo: relatedId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
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

  /// Ensures recurring reminders exist for a housing cost.
  /// Generates monthly occurrences up to [monthsAhead] months into the future.
  /// Skips dates that already have a pending (isDone=false) reminder.
  Future<List<Map<String, dynamic>>> ensureRecurringReminders(
    HousingCost cost, {
    int monthsAhead = 12,
  }) async {
    if (_uid == null) return [];
    if (cost.id == null) return [];

    final baseDate = cost.dueDate;
    if (baseDate == null) return [];

    // Generate recurring monthly dates from the base date
    final today = _normalizeDay(DateTime.now());
    final cutoff = _addMonths(today, monthsAhead);
    final monthlyDates = <DateTime>[];
    var current = _normalizeDay(baseDate);
    var guard = 0;
    while (!current.isAfter(cutoff) && guard < 240) {
      if (!current.isBefore(today)) {
        monthlyDates.add(current);
      }
      current = _addMonths(current, 1);
      guard++;
    }

    if (monthlyDates.isEmpty) return [];

    // Fetch existing reminders for this housing cost that are not done
    final existingSnapshot = await _firestore
        .collection('reminders')
        .where('userId', isEqualTo: _uid)
        .where('itemType', isEqualTo: 'housing')
        .where('itemId', isEqualTo: cost.id)
        .where('isDone', isEqualTo: false)
        .get();

    // Build a set of existing remindAt dates (normalized) to avoid duplicates
    final existingRemindAtDates = existingSnapshot.docs
        .map((doc) {
          final data = doc.data();
          final remindAt = data['remindAt'] as Timestamp?;
          return remindAt != null ? _normalizeDay(remindAt.toDate()) : null;
        })
        .where((d) => d != null)
        .map((d) => d!)
        .toSet();

    final results = <Map<String, dynamic>>[];

    for (final occurrenceDate in monthlyDates) {
      final normalizedDate = _normalizeDay(occurrenceDate);

      // Skip if a reminder already exists for this date
      if (existingRemindAtDates.contains(normalizedDate)) continue;

      // Create a reminder for this occurrence
      final data = {
        'userId': _uid,
        'itemType': 'housing',
        'itemId': cost.id,
        'remindAt': Timestamp.fromDate(normalizedDate),
        'title': 'Payment Reminder: ${cost.name}',
        'note': 'Automatic monthly reminder for your housing cost.',
        'isDone': false,
        'notificationEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('reminders').add(data);
      final doc = await docRef.get();
      results.add({...doc.data()!, 'id': doc.id});
    }

    return results;
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _addMonths(DateTime date, int months) {
    final targetMonth = date.month + months;
    final targetYear = date.year + ((targetMonth - 1) ~/ 12);
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final lastDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(targetYear, normalizedMonth, day);
  }

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
}
