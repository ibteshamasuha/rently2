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
  final DateTime? createdAt;

  RentalRequestModel({
    required this.id,
    required this.tenantId,
    required this.landlordId,
    required this.apartmentId,
    required this.status,
    this.message,
    this.apartmentTitle,
    this.tenantName,
    this.createdAt,
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

    return RentalRequestModel(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      landlordId: data['landlordId'] ?? '',
      apartmentId: data['apartmentId'] ?? '',
      status: data['status'] ?? 'pending',
      message: data['message'],
      apartmentTitle: data['apartmentTitle'],
      tenantName: data['tenantName'],
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'landlordId': landlordId,
      'apartmentId': apartmentId,
      'status': status,
      if (message != null && message!.isNotEmpty) 'message': message,
      if (apartmentTitle != null) 'apartmentTitle': apartmentTitle,
      if (tenantName != null) 'tenantName': tenantName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
