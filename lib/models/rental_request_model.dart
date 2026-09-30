import 'package:cloud_firestore/cloud_firestore.dart';

class RentalRequestModel {
  final String id;
  final String tenantId;
  final String landlordId;
  final String apartmentId;
  final String status; // 'pending', 'approved', 'rejected'
  final String? message;
  final String? apartmentTitle;
  final String? tenantName;
  final DateTime? preferredMoveInDate;
  final DateTime? createdAt;

  final bool deletedByTenant;
  final bool deletedByLandlord;

  RentalRequestModel({
    required this.id,
    required this.tenantId,
    required this.landlordId,
    required this.apartmentId,
    required this.status,
    this.message,
    this.apartmentTitle,
    this.tenantName,
    this.preferredMoveInDate,
    this.createdAt,
    this.deletedByTenant = false,
    this.deletedByLandlord = false,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory RentalRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime? parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt']);
    }

    DateTime? moveInDate;
    if (data['preferredMoveInDate'] is Timestamp) {
      moveInDate = (data['preferredMoveInDate'] as Timestamp).toDate();
    } else if (data['preferredMoveInDate'] is String) {
      moveInDate = DateTime.tryParse(data['preferredMoveInDate']);
    }

    return RentalRequestModel(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      landlordId: data['landlordId'] ?? '',
      apartmentId: data['apartmentId'] ?? '',
      status: data['status'] ?? 'pending',
      message: data['message'],
      apartmentTitle: data['apartmentTitle'],
      tenantName: data['tenantName'],
      preferredMoveInDate: moveInDate,
      createdAt: parsedDate,
      deletedByTenant: data['deletedByTenant'] ?? false,
      deletedByLandlord: data['deletedByLandlord'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'landlordId': landlordId,
      'apartmentId': apartmentId,
      'status': status,
      'message': message ?? '',
      if (apartmentTitle != null) 'apartmentTitle': apartmentTitle,
      if (tenantName != null) 'tenantName': tenantName,
      'preferredMoveInDate': preferredMoveInDate != null ? Timestamp.fromDate(preferredMoveInDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'deletedByTenant': deletedByTenant,
      'deletedByLandlord': deletedByLandlord,
    };
  }
}
