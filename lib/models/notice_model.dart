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
  final String? targetType; // 'all', 'apartment', 'tenant'
  final DateTime? createdAt;
  final List<String>? targetTenantIds;
  final List<String> hiddenBy;

  NoticeModel({
    required this.id,
    required this.title,
    required this.message,
    required this.authorId,
    this.authorName,
    this.authorRole,
    this.isPublic = true,
    this.targetTenantId,
    this.targetTenantIds,
    this.apartmentId,
    this.targetType,
    this.createdAt,
    this.hiddenBy = const [],
  });

  /// Convenient relationship-based accessors
  String get landlordId => authorId;
  String? get tenantId => targetTenantId;

  factory NoticeModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime? parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt']);
    }

    final rawTargetTenantId = data['targetTenantId'] ?? data['tenantId'];
    final rawAuthorId = data['authorId'] ?? data['landlordId'] ?? '';
    final rawApartmentId = data['apartmentId'];
    final rawTargetType = data['targetType'] as String? ??
        (rawTargetTenantId != null ? 'tenant' : (rawApartmentId != null ? 'apartment' : 'all'));
    
    final List<String> targetTenantIdsList = 
        data['targetTenantIds'] != null ? List<String>.from(data['targetTenantIds']) : [];
        
    final List<String> hiddenByList = 
        data['hiddenBy'] != null ? List<String>.from(data['hiddenBy']) : [];

    return NoticeModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      authorId: rawAuthorId,
      authorName: data['authorName'],
      authorRole: data['authorRole'],
      isPublic: data['isPublic'] ?? true,
      targetTenantId: rawTargetTenantId as String?,
      targetTenantIds: targetTenantIdsList,
      apartmentId: rawApartmentId as String?,
      targetType: rawTargetType,
      createdAt: parsedDate,
      hiddenBy: hiddenByList,
    );
  }

  Map<String, dynamic> toMap() {
    final effectiveTargetType = targetType ??
        (targetTenantId != null && targetTenantId!.isNotEmpty
            ? 'tenant'
            : (apartmentId != null && apartmentId!.isNotEmpty ? 'apartment' : 'all'));

    return {
      'title': title,
      'message': message,
      'authorId': authorId,
      'landlordId': authorId,
      'isPublic': isPublic,
      if (targetTenantId != null) 'targetTenantId': targetTenantId,
      if (targetTenantId != null) 'tenantId': targetTenantId,
      if (targetTenantIds != null) 'targetTenantIds': targetTenantIds,
      if (apartmentId != null) 'apartmentId': apartmentId,
      'targetType': effectiveTargetType,
      if (authorName != null) 'authorName': authorName,
      if (authorRole != null) 'authorRole': authorRole,
      'hiddenBy': hiddenBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
