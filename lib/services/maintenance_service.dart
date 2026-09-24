import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/maintenance_request_model.dart';
import 'notification_service.dart';

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference get _maintenanceRef => _firestore.collection('maintenanceRequests');

  Future<void> submitRequest({
    required String tenantId,
    required String landlordId,
    required String apartmentId,
    required String title,
    required String description,
    String? issueType,
    String? photoUrl,
    String? apartmentTitle,
    String? tenantName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    // Enforce authenticated tenant UID (never trust client-supplied tenantId parameter)
    final effectiveTenantId = user.uid;

    // Strict Active Tenancy Verification (Issue 4):
    // A tenant can only submit maintenance requests for their active approved tenancy.
    final approvedLeaseQuery = await _firestore
        .collection('rentalRequests')
        .where('tenantId', isEqualTo: effectiveTenantId)
        .where('status', isEqualTo: 'approved')
        .get();

    if (approvedLeaseQuery.docs.isEmpty) {
      throw 'You do not have an active approved tenancy. Maintenance requests can only be submitted for apartments you currently live in.';
    }

    String effectiveApartmentId = '';
    String effectiveLandlordId = '';
    String? effectiveApartmentTitle;

    // Check approved leases to identify the currently active apartment where the tenant lives
    for (final leaseDoc in approvedLeaseQuery.docs) {
      final leaseData = leaseDoc.data();
      final aId = (leaseData['apartmentId'] as String?)?.trim() ?? '';
      if (aId.isNotEmpty) {
        final aptDoc = await _firestore.collection('apartments').doc(aId).get();
        if (aptDoc.exists &&
            aptDoc.data()?['status'] == 'rented' &&
            aptDoc.data()?['currentTenantId'] == effectiveTenantId) {
          effectiveApartmentId = aId;
          effectiveLandlordId = (aptDoc.data()?['landlordId'] as String?)?.trim() ??
              (leaseData['landlordId'] as String?)?.trim() ?? landlordId;
          effectiveApartmentTitle = (aptDoc.data()?['title'] as String?)?.trim() ??
              (leaseData['apartmentTitle'] as String?)?.trim() ?? apartmentTitle;
          break;
        }
      }
    }

    // Fallback to the approved lease record
    if (effectiveApartmentId.isEmpty) {
      final leaseData = approvedLeaseQuery.docs.first.data();
      effectiveApartmentId = (leaseData['apartmentId'] as String?)?.trim() ?? apartmentId;
      effectiveLandlordId = (leaseData['landlordId'] as String?)?.trim() ?? landlordId;
      effectiveApartmentTitle = (leaseData['apartmentTitle'] as String?)?.trim() ?? apartmentTitle;
    }

    final request = MaintenanceRequestModel(
      id: '',
      tenantId: effectiveTenantId,
      landlordId: effectiveLandlordId,
      apartmentId: effectiveApartmentId,
      title: title.trim(),
      description: description.trim(),
      status: 'pending',
      issueType: issueType,
      photoUrl: photoUrl,
      apartmentTitle: effectiveApartmentTitle,
      tenantName: tenantName ?? user.displayName,
      createdAt: DateTime.now(),
    );

    final docRef = await _maintenanceRef.add(request.toMap());

    // Send notification to the actual landlord of that apartment (Issue 6)
    try {
      await _notificationService.createNotification(
        recipientId: effectiveLandlordId,
        type: 'maintenance_request',
        title: 'New Maintenance Request',
        message: '${request.tenantName ?? "Tenant"} submitted a maintenance issue: "${title.trim()}" at "${effectiveApartmentTitle ?? "your apartment"}".',
        apartmentId: effectiveApartmentId,
        maintenanceRequestId: docRef.id,
      );
    } catch (_) {}
  }

  // Alias
  Future<void> createTicket({
    required String tenantId,
    required String landlordId,
    required String apartmentId,
    required String title,
    required String description,
    String? issueType,
    String? photoUrl,
    String? apartmentTitle,
    String? tenantName,
  }) => submitRequest(
    tenantId: tenantId,
    landlordId: landlordId,
    apartmentId: apartmentId,
    title: title,
    description: description,
    issueType: issueType,
    photoUrl: photoUrl,
    apartmentTitle: apartmentTitle,
    tenantName: tenantName,
  );

  Stream<List<MaintenanceRequestModel>> getTenantRequests(String tenantId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null && user.uid == tenantId) ? user.uid : tenantId;
    return _maintenanceRef
        .where('tenantId', isEqualTo: effectiveId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceRequestModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<MaintenanceRequestModel>> getLandlordRequests(String landlordId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null && user.uid == landlordId) ? user.uid : landlordId;
    return _maintenanceRef
        .where('landlordId', isEqualTo: effectiveId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceRequestModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateStatus({
    required MaintenanceRequestModel request,
    required String newStatus, // 'pending', 'in-progress', 'completed', 'rejected'
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    // Enforce maintaining existing immutable IDs
    await _maintenanceRef.doc(request.id).update({
      'tenantId': request.tenantId,
      'landlordId': request.landlordId,
      'apartmentId': request.apartmentId,
      'status': newStatus,
    });

    // Notify the tenant of maintenance status update (Issue 6)
    try {
      await _notificationService.createNotification(
        recipientId: request.tenantId,
        type: 'maintenance_status',
        title: 'Maintenance Status: $newStatus',
        message: 'Your maintenance request "${request.title}" is now marked as "$newStatus".',
        apartmentId: request.apartmentId,
        maintenanceRequestId: request.id,
      );
    } catch (_) {}
  }

  Future<void> deleteRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';
    await _maintenanceRef.doc(requestId).delete();
  }
}
