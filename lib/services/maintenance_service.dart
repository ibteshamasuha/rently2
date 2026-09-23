import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/maintenance_request_model.dart';

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _maintenanceRef => _firestore.collection('maintenanceRequests');

  Future<void> submitRequest({
    required String tenantId,
    required String landlordId,
    required String apartmentId,
    required String title,
    required String description,
    String? apartmentTitle,
    String? tenantName,
  }) async {
    final request = MaintenanceRequestModel(
      id: '',
      tenantId: tenantId,
      landlordId: landlordId,
      apartmentId: apartmentId,
      title: title,
      description: description,
      status: 'pending',
      apartmentTitle: apartmentTitle,
      tenantName: tenantName,
      createdAt: DateTime.now(),
    );

    await _maintenanceRef.add(request.toMap());
  }

  Stream<List<MaintenanceRequestModel>> getTenantRequests(String tenantId) {
    return _maintenanceRef
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceRequestModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<MaintenanceRequestModel>> getLandlordRequests(String landlordId) {
    return _maintenanceRef
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceRequestModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateStatus({
    required MaintenanceRequestModel request,
    required String newStatus, // 'pending', 'in-progress', 'completed', 'rejected'
  }) async {
    await _maintenanceRef.doc(request.id).update({
      'tenantId': request.tenantId,
      'landlordId': request.landlordId,
      'apartmentId': request.apartmentId,
      'status': newStatus,
    });
  }

  Future<void> deleteRequest(String requestId) async {
    await _maintenanceRef.doc(requestId).delete();
  }
}
