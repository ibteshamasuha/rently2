import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rental_request_model.dart';
import 'notification_service.dart';

class RentalRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

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

    final docId = '${effectiveTenantId}_$apartmentId';

    // Strictly enforce: A tenant can have AT MOST ONE rental request for a particular apartment.
    // Restriction applies regardless of current status (pending, approved, or rejected).
    // Rejection does NOT reset the request.
    try {
      final existingDoc = await _requestsRef.doc(docId).get();
      if (existingDoc.exists && existingDoc.data() != null) {
        throw 'You have already submitted a rental request for this apartment.';
      }
    } catch (e) {
      if (e is String && e.contains('already submitted')) {
        rethrow;
      }
    }

    try {
      final existingQuery = await _requestsRef
          .where('tenantId', isEqualTo: effectiveTenantId)
          .where('apartmentId', isEqualTo: apartmentId)
          .limit(1)
          .get();
      if (existingQuery.docs.isNotEmpty) {
        throw 'You have already submitted a rental request for this apartment.';
      }
    } catch (e) {
      if (e is String && e.contains('already submitted')) {
        rethrow;
      }
    }

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

    String? effectiveTenantName = tenantName;
    if (effectiveTenantName == null || effectiveTenantName.trim().isEmpty) {
      effectiveTenantName = user.displayName;
    }
    if (effectiveTenantName == null || effectiveTenantName.trim().isEmpty) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          effectiveTenantName = userDoc.data()!['name'] as String?;
        }
      } catch (_) {}
    }
    effectiveTenantName ??= 'Tenant';

    final newRequest = RentalRequestModel(
      id: docId,
      tenantId: effectiveTenantId,
      landlordId: effectiveLandlordId,
      apartmentId: apartmentId,
      status: 'pending',
      message: message,
      apartmentTitle: effectiveTitle,
      tenantName: effectiveTenantName,
      preferredMoveInDate: preferredMoveInDate,
      createdAt: DateTime.now(),
    );

    await _requestsRef.doc(docId).set(newRequest.toMap());

    // Send notification to actual apartment landlord (Issue 6)
    try {
      await _notificationService.createNotification(
        recipientId: effectiveLandlordId,
        type: 'rental_request',
        title: 'New Rental Application',
        message: '$effectiveTenantName applied for "${effectiveTitle ?? "your apartment"}".',
        apartmentId: apartmentId,
        rentalRequestId: docId,
      );
    } catch (_) {}
  }

  /// Retrieves any existing rental request submitted by the tenant for the apartment
  Future<RentalRequestModel?> getTenantRequestForApartment({
    required String tenantId,
    required String apartmentId,
  }) async {
    final user = _auth.currentUser;
    final effectiveTenantId = (user != null && user.uid.isNotEmpty) ? user.uid : tenantId;
    if (effectiveTenantId.isEmpty || apartmentId.isEmpty) return null;

    final docId = '${effectiveTenantId}_$apartmentId';
    try {
      final doc = await _requestsRef.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return RentalRequestModel.fromFirestore(doc);
      }
    } catch (_) {}

    try {
      final query = await _requestsRef
          .where('tenantId', isEqualTo: effectiveTenantId)
          .where('apartmentId', isEqualTo: apartmentId)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return RentalRequestModel.fromFirestore(query.docs.first);
      }
    } catch (_) {}

    return null;
  }

  /// Real-time stream of the tenant's request for a specific apartment
  Stream<RentalRequestModel?> streamTenantRequestForApartment({
    required String tenantId,
    required String apartmentId,
  }) {
    final user = _auth.currentUser;
    final effectiveTenantId = (user != null && user.uid.isNotEmpty) ? user.uid : tenantId;
    if (effectiveTenantId.isEmpty || apartmentId.isEmpty) {
      return Stream.value(null);
    }
    final docId = '${effectiveTenantId}_$apartmentId';
    return _requestsRef.doc(docId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return RentalRequestModel.fromFirestore(doc);
      }
      return null;
    }).handleError((_) => null);
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
            .where((req) => !req.deletedByTenant)
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
            .where((req) => !req.deletedByLandlord)
            .toList());
  }

  Future<void> updateRequestStatus({
    required RentalRequestModel request,
    required String newStatus, // 'approved' or 'rejected'
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    // Prevent duplicate approvals
    if (request.status == 'approved' && newStatus == 'approved') {
      return;
    }

    // Verify landlord ownership (or admin)
    if (request.landlordId != user.uid) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final role = userDoc.data()?['role']?.toString().toLowerCase();
      if (role != 'admin') {
        throw 'Unauthorized: Only the apartment owner can approve or reject rental requests.';
      }
    }

    // If approving, ensure apartment is not already rented to a different active tenant
    if (newStatus == 'approved') {
      final aptDoc = await _firestore.collection('apartments').doc(request.apartmentId).get();
      if (aptDoc.exists) {
        final aptData = aptDoc.data();
        if (aptData != null &&
            aptData['status'] == 'rented' &&
            aptData['currentTenantId'] != null &&
            aptData['currentTenantId'] != request.tenantId) {
          throw 'This apartment is already occupied by another active tenant.';
        }
      }
    }

    // Enforce maintaining existing immutable IDs
    await _requestsRef.doc(request.id).update({
      'tenantId': request.tenantId,
      'landlordId': request.landlordId,
      'apartmentId': request.apartmentId,
      'status': newStatus,
    });

    if (newStatus == 'approved') {
      // 1. Update apartment status to rented and assign currentTenantId (Issue 3)
      try {
        await _firestore.collection('apartments').doc(request.apartmentId).update({
          'status': 'rented',
          'currentTenantId': request.tenantId,
        });
      } catch (_) {}

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

      // 2. Automatically decline other pending requests for the same apartment
      try {
        final otherPending = await _requestsRef
            .where('apartmentId', isEqualTo: request.apartmentId)
            .where('status', isEqualTo: 'pending')
            .get();

        for (final doc in otherPending.docs) {
          if (doc.id != request.id) {
            await doc.reference.update({'status': 'rejected'});
            final otherData = doc.data() as Map<String, dynamic>?;
            final otherTenantId = otherData?['tenantId'] as String?;
            if (otherTenantId != null && otherTenantId.isNotEmpty) {
              await _notificationService.createNotification(
                recipientId: otherTenantId,
                type: 'rental_rejection',
                title: 'Rental Application Update',
                message: 'The apartment "${request.apartmentTitle ?? 'listing'}" has been rented to another applicant.',
                apartmentId: request.apartmentId,
                rentalRequestId: doc.id,
              );
            }
          }
        }
      } catch (_) {}

      // 3. Send approval notification strictly to the approved tenant (Issue 6 & 7)
      try {
        await _notificationService.createNotification(
          recipientId: request.tenantId,
          type: 'rental_approval',
          title: 'Rental Request Approved!',
          message: 'Your rental request has been approved for "${request.apartmentTitle ?? 'the apartment'}".',
          apartmentId: request.apartmentId,
          rentalRequestId: request.id,
        );
      } catch (_) {}
    } else if (newStatus == 'rejected') {
      // Send rejection notification to tenant (Issue 6)
      try {
        await _notificationService.createNotification(
          recipientId: request.tenantId,
          type: 'rental_rejection',
          title: 'Rental Request Declined',
          message: 'Your rental request for "${request.apartmentTitle ?? 'the apartment'}" was declined by the landlord.',
          apartmentId: request.apartmentId,
          rentalRequestId: request.id,
        );
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

  Future<void> hideRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    final doc = await _requestsRef.doc(requestId).get();
    if (!doc.exists || doc.data() == null) return;
    
    final request = RentalRequestModel.fromFirestore(doc);
    
    // Check if the current user is an active tenant for this apartment
    if (request.status == 'approved') {
       final aptDoc = await _firestore.collection('apartments').doc(request.apartmentId).get();
       if (aptDoc.exists) {
         final currentTenantId = aptDoc.data()?['currentTenantId'];
         if (currentTenantId == request.tenantId && user.uid == request.tenantId) {
             throw 'Cannot hide an active or approved tenancy from your history while you are the current tenant.';
         }
       }
    }

    if (request.tenantId == user.uid) {
       await _requestsRef.doc(requestId).update({'deletedByTenant': true});
    } else if (request.landlordId == user.uid) {
       await _requestsRef.doc(requestId).update({'deletedByLandlord': true});
    } else {
       throw 'Unauthorized to hide this request.';
    }
    
    // Optional: If both have hidden it, we could delete it, but soft-delete is fine.
  }

  Future<void> deleteRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';
    await _requestsRef.doc(requestId).delete();
  }
}
