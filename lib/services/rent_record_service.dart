import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rent_record_model.dart';

class RentRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _recordsRef => _firestore.collection('rent_records');

  Stream<List<RentRecordModel>> getTenantRentRecords(String tenantId) {
    return _recordsRef
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentRecordModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<RentRecordModel>> getLandlordRentRecords(String landlordId) {
    return _recordsRef
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentRecordModel.fromFirestore(doc))
            .toList());
  }

  Future<void> createRentRecord(RentRecordModel record) async {
    await _recordsRef.add(record.toMap());
  }

  Future<void> updatePaymentStatus({
    required String recordId,
    required String status, // 'paid' or 'unpaid'
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
    };
    if (status == 'paid') {
      updateData['paidAt'] = FieldValue.serverTimestamp();
    } else {
      updateData['paidAt'] = null;
    }
    await _recordsRef.doc(recordId).update(updateData);
  }

  Future<void> deleteRentRecord(String recordId) async {
    await _recordsRef.doc(recordId).delete();
  }
}
