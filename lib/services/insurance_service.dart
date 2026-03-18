import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../Insurance/models/insurance_model.dart';
import '../Loan_Screen/models/document_model.dart';

class InsuranceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ffpvault',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Insurance Policies ──────────────────────────────────────────────────────

  Future<List<InsurancePolicy>> fetchInsurances({String? category}) async {
    if (_uid == null) return [];

    Query query = _firestore
        .collection('insurancePolicies')
        .where('userId', isEqualTo: _uid);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => InsurancePolicy.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          }),
        )
        .toList();
  }

  Stream<List<InsurancePolicy>> streamInsurances({String? category}) {
    if (_uid == null) return Stream.value([]);

    Query query = _firestore
        .collection('insurancePolicies')
        .where('userId', isEqualTo: _uid);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => InsurancePolicy.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList(),
    );
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
    if (_uid == null) return [];

    // Fetch all policies; filter/sort in-memory to avoid Firestore index issues
    final snapshot = await _firestore
        .collection('insurancePolicies')
        .where('userId', isEqualTo: _uid)
        .get();

    final policies = snapshot.docs
        .map(
          (doc) => InsurancePolicy.fromJson({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .where((p) {
          final r = p.renewalDate;
          if (r == null) return false;
          if (from != null && r.isBefore(from)) return false;
          if (to != null && r.isAfter(to)) return false;
          return true;
        })
        .toList()
      ..sort((a, b) {
        final aDate = a.renewalDate;
        final bDate = b.renewalDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });

    return policies;
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
    final ref = _storage.ref().child('$module/$_uid/$fileName');

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: _getMimeType(file.path)),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    final Map<String, dynamic> docData = <String, dynamic>{
      'userId': _uid,
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

    // Update relationship if needed
    if (relatedType == 'insurance' && relatedId != null) {
      final Map<String, Object> updateData = <String, Object>{
        'documents': FieldValue.arrayUnion(<String>[docRef.id]),
      };
      await _firestore
          .collection('insurancePolicies')
          .doc(relatedId)
          .update(updateData);
    }

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

  Future<void> deleteDocument(String id) async {
    final doc = await _firestore.collection('documents').doc(id).get();
    if (doc.exists) {
      try {
        final data = doc.data();
        if (data != null &&
            data['mimeType'] != 'application/vnd.anick-giroux.folder' &&
            _uid != null &&
            data['module'] != null &&
            data['filename'] != null) {
          await _storage
              .ref()
              .child('${data['module']}/$_uid/${data['filename']}')
              .delete();
        }
        await _firestore.collection('documents').doc(id).delete();
      } catch (e) {
        debugPrint('Error deleting document: $e');
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
      default:
        return 'application/octet-stream';
    }
  }
}
