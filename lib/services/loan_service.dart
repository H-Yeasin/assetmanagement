import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

    // Use a temporary variable to help with type inference if needed
    final docRef = await _firestore.collection('documents').add(docData);

    // Update relationship if needed
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
        .map(
          (doc) => DocumentFile.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          }),
        )
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
      'path': '', // No physical file path
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
      try {
        // Try to delete from storage if we have the filename/path logic sorted
        // For simplicity, we'll delete the metadata doc first
        await _firestore.collection('documents').doc(id).delete();
      } catch (e) {
        print('Error deleting document from storage: $e');
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

    // Simplistic implementation: get active loans and return them
    // Real implementation would calculate occurrences between from/to
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

    final loans = await fetchLoans(status: 'completed');
    return loans
        .map(
          (l) => {
            'date':
                l.completedAt?.toIso8601String() ??
                DateTime.now().toIso8601String(),
            'items': [l.toJson()],
          },
        )
        .toList();
  }

  Stream<List<dynamic>> streamPastActivities({DateTime? from, DateTime? to}) {
    if (_uid == null) return Stream.value([]);

    return streamLoans(status: 'completed').map((loans) {
      return loans
          .map(
            (l) => {
              'date':
                  l.completedAt?.toIso8601String() ??
                  DateTime.now().toIso8601String(),
              'items': [l.toJson()],
            },
          )
          .toList();
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
      'createdAt': FieldValue.serverTimestamp(),
    };

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
    return snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
        .toList();
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

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList(),
    );
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
    await _firestore.collection('reminders').doc(id).update({'isDone': true});
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
      default:
        return 'application/octet-stream';
    }
  }
}
