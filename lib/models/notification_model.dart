import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String recipientId;
  final String type; // 'inquiry', 'inquiry_reply', 'rental_request', 'rental_approval', 'rental_rejection', 'maintenance_request', 'maintenance_status', 'rent_reminder', 'notice'
  final String title;
  final String message;
  final String? apartmentId;
  final String? rentalRequestId;
  final String? inquiryId;
  final String? maintenanceRequestId;
  final String? rentRecordId;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.apartmentId,
    this.rentalRequestId,
    this.inquiryId,
    this.maintenanceRequestId,
    this.rentRecordId,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime? parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt']);
    }

    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      type: data['type'] ?? 'general',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      apartmentId: data['apartmentId'],
      rentalRequestId: data['rentalRequestId'],
      inquiryId: data['inquiryId'],
      maintenanceRequestId: data['maintenanceRequestId'],
      rentRecordId: data['rentRecordId'],
      isRead: data['isRead'] ?? false,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'message': message,
      if (apartmentId != null && apartmentId!.isNotEmpty) 'apartmentId': apartmentId,
      if (rentalRequestId != null && rentalRequestId!.isNotEmpty) 'rentalRequestId': rentalRequestId,
      if (inquiryId != null && inquiryId!.isNotEmpty) 'inquiryId': inquiryId,
      if (maintenanceRequestId != null && maintenanceRequestId!.isNotEmpty) 'maintenanceRequestId': maintenanceRequestId,
      if (rentRecordId != null && rentRecordId!.isNotEmpty) 'rentRecordId': rentRecordId,
      'isRead': isRead,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
