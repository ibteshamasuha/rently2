import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeModel {
  final String id;
  final String title;
  final String message;
  final String authorId;
  final String? authorName;
  final String? authorRole;
  final bool isPublic;
  final String? targetTenantId;
  final String? apartmentId;
  final DateTime? createdAt;

  NoticeModel({
    required this.id,
    required this.title,
    required this.message,
    required this.authorId,
    this.authorName,
    this.authorRole,
    this.isPublic = true,
    this.targetTenantId,
    this.apartmentId,
    this.createdAt,
  });

  factory NoticeModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime? parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt']);
    }

    return NoticeModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'],
      authorRole: data['authorRole'],
      isPublic: data['isPublic'] ?? true,
      targetTenantId: data['targetTenantId'],
      apartmentId: data['apartmentId'],
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'authorId': authorId,
      'isPublic': isPublic,
      if (targetTenantId != null) 'targetTenantId': targetTenantId,
      if (apartmentId != null) 'apartmentId': apartmentId,
      if (authorName != null) 'authorName': authorName,
      if (authorRole != null) 'authorRole': authorRole,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
