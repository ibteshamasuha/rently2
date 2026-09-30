import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceRequestModel {
  final String id;
  final String tenantId;
  final String landlordId;
  final String apartmentId;
  final String title;
  final String description;
  final String status; // 'pending', 'in-progress', 'completed', 'rejected'
  final String? issueType; // Plumbing, Electrical, HVAC, Appliance, Structural, Other
  final String? photoUrl;
  final List<String>? photos;
  final String? apartmentTitle;
  final String? tenantName;
  final DateTime? createdAt;

  MaintenanceRequestModel({
    required this.id,
    required this.tenantId,
    required this.landlordId,
    required this.apartmentId,
    required this.title,
    required this.description,
    required this.status,
    this.issueType,
    this.photoUrl,
    this.photos,
    this.apartmentTitle,
    this.tenantName,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in-progress';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';

  factory MaintenanceRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime? parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt']);
    }

    return MaintenanceRequestModel(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      landlordId: data['landlordId'] ?? '',
      apartmentId: data['apartmentId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      issueType: data['issueType'] ?? 'General',
      photoUrl: data['photoUrl'],
      photos: data['photos'] != null ? List<String>.from(data['photos']) : null,
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
      'title': title,
      'description': description,
      if (status.isNotEmpty) 'status': status,
      if (issueType != null) 'issueType': issueType,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photos != null && photos!.isNotEmpty) 'photos': photos,
      if (apartmentTitle != null) 'apartmentTitle': apartmentTitle,
      if (tenantName != null) 'tenantName': tenantName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
