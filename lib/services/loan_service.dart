import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../Loan_Screen/models/loan_model.dart';
import '../Loan_Screen/models/document_model.dart';

class LoanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ffpvault',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Loans ──────────────────────────────────────────────────────────────────

  Future<List<Loan>> fetchLoans({String? status}) async {
    if (_uid == null) return [];

    Query query = _firestore
        .collection('loans')
        .where('userId', isEqualTo: _uid);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => Loan.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          }),
        )
        .toList();
  }

  Stream<List<Loan>> streamLoans({String? status}) {
    if (_uid == null) return Stream.value([]);

    Query query = _firestore
        .collection('loans')
        .where('userId', isEqualTo: _uid);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => Loan.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList(),
    );
  }

  Future<Loan> getLoan(String id) async {
    final doc = await _firestore.collection('loans').doc(id).get();
    if (!doc.exists) throw Exception('Loan not found');
    return Loan.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<Loan> createLoan(Loan loan) async {
    if (_uid == null) throw Exception('User not logged in');

    final data = loan.toJson();
    data['userId'] = _uid;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    final docRef = await _firestore.collection('loans').add(data);
    final doc = await docRef.get();
    return Loan.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<Loan> updateLoan(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('loans').doc(id).update(updates);
    return getLoan(id);
  }

  Future<void> deleteLoan(String id) async {
    await _firestore.collection('loans').doc(id).delete();
  }

  Future<Loan> markCompleted(String id) async {
    return updateLoan(id, {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Documents ─────────────────────────────────────────────────────────────

  Future<DocumentFile> uploadDocument(
    File file, {
    String module = 'loans',
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

    if (relatedType == 'loans' && relatedId != null) {
      final Map<String, dynamic> updateData = <String, dynamic>{
        'documents': FieldValue.arrayUnion(<String>[docRef.id]),
      };
      await _firestore.collection('loans').doc(relatedId).update(updateData);
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

  Future<DocumentFile> createFolder(String name, String module) async {
    if (_uid == null) throw Exception('User not logged in');

    final Map<String, dynamic> folderData = <String, dynamic>{
      'userId': _uid,
      'module': module,
      'originalName': name,
      'displayName': name,
      'filename': 'folder_$name',
      'mimeType': 'application/vnd.anick-giroux.folder',
      'size': 0,
      'path': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection('documents').add(folderData);
    final docSnapshot = await docRef.get();
    final Map<String, dynamic> finalData = Map<String, dynamic>.from(
      docSnapshot.data()!,
    );
    finalData['id'] = docRef.id;
    return DocumentFile.fromJson(finalData);
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

  // ── Finance Logic ──────────────────────────────────────────────────────────

  Future<List<dynamic>> fetchUpcomingPayments({
    DateTime? from,
    DateTime? to,
  }) async {
    if (_uid == null) return [];

    final loans = await fetchLoans(status: 'active');
    return loans
        .map(
          (l) => {
            'date':
                l.paymentDate?.toIso8601String() ??
                DateTime.now().toIso8601String(),
            'items': [l.toJson()],
          },
        )
        .toList();
  }

  Stream<List<dynamic>> streamUpcomingPayments({DateTime? from, DateTime? to}) {
    if (_uid == null) return Stream.value([]);
    return streamLoans(status: 'active').map((loans) {
      return loans
          .map(
            (l) => {
              'date':
                  l.paymentDate?.toIso8601String() ??
                  DateTime.now().toIso8601String(),
              'items': [l.toJson()],
            },
          )
          .toList();
    });
  }

  Future<List<dynamic>> fetchPastActivities({
    DateTime? from,
    DateTime? to,
  }) async {
    if (_uid == null) return [];

    final snapshot = await _firestore
        .collection('reminders')
        .where('userId', isEqualTo: _uid)
        .where('isDone', isEqualTo: true)
        .get();

    final activities = snapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();

    activities.sort((a, b) {
      final aDate =
          (a['doneAt'] as Timestamp?)?.toDate() ??
          (a['remindAt'] as Timestamp?)?.toDate() ??
          DateTime.now();
      final bDate =
          (b['doneAt'] as Timestamp?)?.toDate() ??
          (b['remindAt'] as Timestamp?)?.toDate() ??
          DateTime.now();
      return bDate.compareTo(aDate);
    });

    return activities;
  }

  Stream<List<dynamic>> streamPastActivities({DateTime? from, DateTime? to}) {
    if (_uid == null) return Stream.value([]);

    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: _uid)
        .where('isDone', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final activities = snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList();

          activities.sort((a, b) {
            final aDate =
                (a['doneAt'] as Timestamp?)?.toDate() ??
                (a['remindAt'] as Timestamp?)?.toDate() ??
                DateTime.now();
            final bDate =
                (b['doneAt'] as Timestamp?)?.toDate() ??
                (b['remindAt'] as Timestamp?)?.toDate() ??
                DateTime.now();
            return bDate.compareTo(aDate);
          });

          return activities;
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
    final reminders = snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
        .toList();
    reminders.sort((a, b) {
      final aDate = (a['remindAt'] as Timestamp?)?.toDate();
      final bDate = (b['remindAt'] as Timestamp?)?.toDate();
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return reminders;
  }

  Stream<List<dynamic>> streamUpcomingReminders({
    DateTime? from,
    DateTime? to,
  }) {
    if (_uid == null) return Stream.value([]);

    Query query = _firestore
        .collection('reminders')
        .where('userId', isEqualTo: _uid)
        .where('isDone', isEqualTo: false);

    return query.snapshots().map((snapshot) {
      final reminders = snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
      reminders.sort((a, b) {
        final aDate = (a['remindAt'] as Timestamp?)?.toDate();
        final bDate = (b['remindAt'] as Timestamp?)?.toDate();
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
      return reminders;
    });
  }

  Stream<int> streamDocumentsCount() {
    if (_uid == null) return Stream.value(0);
    return _firestore
        .collection('documents')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markReminderDone(String id) async {
    await _firestore.collection('reminders').doc(id).update({
      'isDone': true,
      'notificationEnabled': false,
      'doneAt': Timestamp.fromDate(DateTime.now()),
    });
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
