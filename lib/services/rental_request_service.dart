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

      // Auto-generate initial Rent Record starting from this month
      try {
        final now = DateTime.now();
        final currentMonth = '${_monthName(now.month)} ${now.year}';
        num aptRent = 15000;
        try {
          final aptDoc = await _firestore.collection('apartments').doc(request.apartmentId).get();
          if (aptDoc.exists && aptDoc.data() != null) {
            final data = aptDoc.data()!;
            if (data['rent'] is num) {
              aptRent = data['rent'] as num;
            }
          }
        } catch (_) {}

        await _firestore.collection('rent_records').add({
          'tenantId': request.tenantId,
          'landlordId': request.landlordId,
          'apartmentId': request.apartmentId,
          'amount': aptRent,
          'month': currentMonth,
          'status': 'unpaid',
          'apartmentTitle': request.apartmentTitle,
          'tenantName': request.tenantName,
          'createdAt': FieldValue.serverTimestamp(),
          'paidAt': null,
        });

        // Notify tenant about approval and rent commencement
        await _firestore.collection('notices').add({
          'title': 'Rental Request Approved! 🎉',
          'message': 'Your rental request for "${request.apartmentTitle ?? "your apartment"}" has been approved! Your tenancy and monthly rent records start from $currentMonth.',
          'authorId': user.uid,
          'authorName': user.displayName ?? 'Landlord',
          'authorRole': 'landlord',
          'isPublic': false,
          'targetTenantId': request.tenantId,
          'apartmentId': request.apartmentId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return 'Current Month';
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
