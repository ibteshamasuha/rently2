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
    String effectiveLandlordId = landlordId.trim();
    String? effectiveTitle = apartmentTitle?.trim();

    try {
      final aptDoc = await _firestore.collection('apartments').doc(apartmentId).get();
      if (aptDoc.exists && aptDoc.data() != null) {
        final aptData = aptDoc.data()!;
        final storedLandlordId = aptData['landlordId'] as String?;
        if (storedLandlordId != null && storedLandlordId.trim().isNotEmpty) {
          effectiveLandlordId = storedLandlordId.trim();
        }
        final storedTitle = aptData['title'] as String?;
        if (storedTitle != null && storedTitle.trim().isNotEmpty) {
          effectiveTitle = storedTitle.trim();
        }
      }
    } catch (_) {
      // In case apartment doc isn't accessible directly, rely on the passed landlordId
    }

    final queryMap = <String, dynamic>{
      'apartmentId': apartmentId,
      if (effectiveTitle != null && effectiveTitle.isNotEmpty) 'apartmentTitle': effectiveTitle,
      'tenantId': effectiveTenantId,
      if (tenantName != null && tenantName.trim().isNotEmpty)
        'tenantName': tenantName.trim()
      else if (user.displayName != null && user.displayName!.trim().isNotEmpty)
        'tenantName': user.displayName!.trim(),
      'landlordId': effectiveLandlordId,
      'question': question.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _queriesRef.add(queryMap);
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
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ApartmentQueryModel>> getTenantQueries(String tenantId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null) ? user.uid : tenantId;
    if (effectiveId.isEmpty) return Stream.value([]);
    return _queriesRef
        .where('tenantId', isEqualTo: effectiveId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentQueryModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<ApartmentQueryModel>> getApartmentQueriesForTenant(String apartmentId, [String? tenantId]) {
    final user = _auth.currentUser;
    final effectiveId = (user != null) ? user.uid : (tenantId ?? '');
    if (effectiveId.isEmpty) return Stream.value([]);
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
    final effectiveId = (user != null) ? user.uid : landlordId;
    if (effectiveId.isEmpty) return Stream.value([]);
    return _queriesRef
        .where('landlordId', isEqualTo: effectiveId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentQueryModel.fromFirestore(doc))
            .toList());
  }
}
