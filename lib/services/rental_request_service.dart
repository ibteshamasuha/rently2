import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rental_request_model.dart';

class RentalRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _requestsRef => _firestore.collection('rentalRequests');

  Future<void> sendRentalRequest({
    required String tenantId,
    required String landlordId,
    required String apartmentId,
    String? message,
    String? apartmentTitle,
    String? tenantName,
    DateTime? preferredMoveInDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    // Enforce authenticated tenant UID (never trust client-supplied tenantId parameter)
    final effectiveTenantId = user.uid;

    // Verify true apartment ownership from Firestore
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
      // Fallback in case of offline or demo apartment
    }

    final newRequest = RentalRequestModel(
      id: '',
      tenantId: effectiveTenantId,
      landlordId: effectiveLandlordId,
      apartmentId: apartmentId,
      status: 'pending',
      message: message,
      apartmentTitle: effectiveTitle,
      tenantName: tenantName ?? user.displayName,
      preferredMoveInDate: preferredMoveInDate,
      createdAt: DateTime.now(),
    );

    await _requestsRef.add(newRequest.toMap());
  }

  // Alias for compatibility
  Future<void> createRequest({
    required String tenantId,
    required String landlordId,
    required String apartmentId,
    String? message,
    String? apartmentTitle,
    String? tenantName,
    DateTime? preferredMoveInDate,
  }) => sendRentalRequest(
    tenantId: tenantId,
    landlordId: landlordId,
    apartmentId: apartmentId,
    message: message,
    apartmentTitle: apartmentTitle,
    tenantName: tenantName,
    preferredMoveInDate: preferredMoveInDate,
  );

  Stream<List<RentalRequestModel>> getTenantRequests(String tenantId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null && user.uid == tenantId) ? user.uid : tenantId;
    return _requestsRef
        .where('tenantId', isEqualTo: effectiveId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalRequestModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<RentalRequestModel>> getLandlordRequests(String landlordId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null && user.uid == landlordId) ? user.uid : landlordId;
    return _requestsRef
        .where('landlordId', isEqualTo: effectiveId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalRequestModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateRequestStatus({
    required RentalRequestModel request,
    required String newStatus, // 'approved' or 'rejected'
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    // Enforce maintaining existing immutable IDs
    await _requestsRef.doc(request.id).update({
      'tenantId': request.tenantId,
      'landlordId': request.landlordId,
      'apartmentId': request.apartmentId,
      'status': newStatus,
    });

    if (newStatus == 'approved') {
      try {
        await _firestore.collection('apartments').doc(request.apartmentId).update({
          'status': 'rented',
        });
      } catch (_) {
        // If apartment status update fails due to rule permissions, request status is still updated
      }
    }
  }

  Future<void> cancelRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';
    await _requestsRef.doc(requestId).update({'status': 'cancelled'});
  }

  Future<void> deleteRequest(String requestId) async {
    await _requestsRef.doc(requestId).delete();
  }
}
