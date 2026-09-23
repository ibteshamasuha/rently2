import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/maintenance_request_model.dart';

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    String effectiveLandlordId = landlordId;
    String effectiveApartmentId = apartmentId;
    String? effectiveApartmentTitle = apartmentTitle;

    // Verify true apartment ownership from Firestore if available
    try {
      final aptDoc = await _firestore.collection('apartments').doc(apartmentId).get();
      if (aptDoc.exists && aptDoc.data() != null) {
        final aptData = aptDoc.data()!;
        if (aptData['landlordId'] is String && (aptData['landlordId'] as String).isNotEmpty) {
          effectiveLandlordId = aptData['landlordId'] as String;
        }
        if (effectiveApartmentTitle == null || effectiveApartmentTitle.isEmpty) {
          effectiveApartmentTitle = aptData['title'] as String?;
        }
      } else {
        // If placeholder 'active_apartment', find tenant's approved lease if any
        final approvedQuery = await _firestore
            .collection('rentalRequests')
            .where('tenantId', isEqualTo: effectiveTenantId)
            .where('status', isEqualTo: 'approved')
            .limit(1)
            .get();
        if (approvedQuery.docs.isNotEmpty) {
          final approvedData = approvedQuery.docs.first.data();
          if (approvedData['apartmentId'] is String && (approvedData['apartmentId'] as String).isNotEmpty) {
            effectiveApartmentId = approvedData['apartmentId'] as String;
          }
          if (approvedData['landlordId'] is String && (approvedData['landlordId'] as String).isNotEmpty) {
            effectiveLandlordId = approvedData['landlordId'] as String;
          }
          if (approvedData['apartmentTitle'] is String) {
            effectiveApartmentTitle = approvedData['apartmentTitle'] as String;
          }
        }
      }
    } catch (_) {
      // Fallback in case of offline mode or demo apartment
    }

    final request = MaintenanceRequestModel(
      id: '',
      tenantId: effectiveTenantId,
      landlordId: effectiveLandlordId,
      apartmentId: effectiveApartmentId,
      title: title,
      description: description,
      status: 'pending',
      issueType: issueType,
      photoUrl: photoUrl,
      apartmentTitle: effectiveApartmentTitle,
      tenantName: tenantName ?? user.displayName,
      createdAt: DateTime.now(),
    );

    await _maintenanceRef.add(request.toMap());
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
  }

  Future<void> deleteRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';
    await _maintenanceRef.doc(requestId).delete();
  }
}
