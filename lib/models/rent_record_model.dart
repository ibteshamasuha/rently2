import 'package:cloud_firestore/cloud_firestore.dart';

class RentRecordModel {
  final String id;
  final String tenantId;
  final String landlordId;
  final String apartmentId;
  final num amount;
  final String month;
  final String status; // 'paid', 'unpaid'
  final String? apartmentTitle;
  final String? tenantName;
  final DateTime? paidAt;
  final DateTime? createdAt;

  RentRecordModel({
    required this.id,
    required this.tenantId,
    required this.landlordId,
    required this.apartmentId,
    required this.amount,
    required this.month,
    required this.status,
    this.apartmentTitle,
    this.tenantName,
    this.paidAt,
    this.createdAt,
  });

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isUnpaid => status.toLowerCase() == 'unpaid';

  factory RentRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return RentRecordModel(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      landlordId: data['landlordId'] ?? '',
      apartmentId: data['apartmentId'] ?? '',
      amount: data['amount'] ?? 0,
      month: data['month'] ?? '',
      status: data['status'] ?? 'unpaid',
      apartmentTitle: data['apartmentTitle'],
      tenantName: data['tenantName'],
      paidAt: parseDate(data['paidAt']),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'landlordId': landlordId,
      'apartmentId': apartmentId,
      'amount': amount,
      'month': month,
      'status': status,
      if (apartmentTitle != null) 'apartmentTitle': apartmentTitle,
      if (tenantName != null) 'tenantName': tenantName,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
