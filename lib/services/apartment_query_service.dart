import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/apartment_query_model.dart';

class ApartmentQueryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _queriesRef => _firestore.collection('apartment_queries');

  Future<void> sendQuery({
    required String apartmentId,
    required String question,
    required String landlordId,
    String? apartmentTitle,
    String? tenantName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    final effectiveTenantId = user.uid;

    // Verify true apartment owner from Firestore to prevent tampering
    String effectiveLandlordId = landlordId;
    String? effectiveTitle = apartmentTitle;

    try {
      final aptDoc = await _firestore.collection('apartments').doc(apartmentId).get();
      if (aptDoc.exists && aptDoc.data() != null) {
        final aptData = aptDoc.data()!;
        if (aptData['landlordId'] is String && (aptData['landlordId'] as String).isNotEmpty) {
          effectiveLandlordId = aptData['landlordId'] as String;
        }
        if (effectiveTitle == null || effectiveTitle.isEmpty) {
          effectiveTitle = aptData['title'] as String?;
        }
      }
    } catch (_) {
      // Fallback
    }

    final query = ApartmentQueryModel(
      id: '',
      apartmentId: apartmentId,
      apartmentTitle: effectiveTitle,
      tenantId: effectiveTenantId,
      tenantName: tenantName ?? user.displayName,
      landlordId: effectiveLandlordId,
      question: question.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _queriesRef.add(query.toMap());
  }

  Future<void> answerQuery({
    required String queryId,
    required String answer,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    await _queriesRef.doc(queryId).update({
      'answer': answer.trim(),
      'status': 'answered',
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ApartmentQueryModel>> getTenantQueries(String tenantId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null && user.uid == tenantId) ? user.uid : tenantId;
    return _queriesRef
        .where('tenantId', isEqualTo: effectiveId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentQueryModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<ApartmentQueryModel>> getApartmentQueriesForTenant(String apartmentId, String tenantId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null && user.uid == tenantId) ? user.uid : tenantId;
    return _queriesRef
        .where('apartmentId', isEqualTo: apartmentId)
        .where('tenantId', isEqualTo: effectiveId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentQueryModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<ApartmentQueryModel>> getLandlordQueries(String landlordId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null && user.uid == landlordId) ? user.uid : landlordId;
    return _queriesRef
        .where('landlordId', isEqualTo: effectiveId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentQueryModel.fromFirestore(doc))
            .toList());
  }
}
