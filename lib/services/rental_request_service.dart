import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_request_model.dart';

class RentalRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    final newRequest = RentalRequestModel(
      id: '',
      tenantId: tenantId,
      landlordId: landlordId,
      apartmentId: apartmentId,
      status: 'pending',
      message: message,
      apartmentTitle: apartmentTitle,
      tenantName: tenantName,
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
    return _requestsRef
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalRequestModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<RentalRequestModel>> getLandlordRequests(String landlordId) {
    return _requestsRef
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalRequestModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateRequestStatus({
    required RentalRequestModel request,
    required String newStatus, // 'approved' or 'rejected'
  }) async {
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

  Future<void> deleteRequest(String requestId) async {
    await _requestsRef.doc(requestId).delete();
  }
}
