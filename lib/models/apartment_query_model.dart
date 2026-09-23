import 'package:cloud_firestore/cloud_firestore.dart';

class ApartmentQueryModel {
  final String id;
  final String apartmentId;
  final String? apartmentTitle;
  final String tenantId;
  final String? tenantName;
  final String landlordId;
  final String question;
  final String? answer;
  final String status; // 'pending', 'answered'
  final DateTime? createdAt;
  final DateTime? answeredAt;

  ApartmentQueryModel({
    required this.id,
    required this.apartmentId,
    this.apartmentTitle,
    required this.tenantId,
    this.tenantName,
    required this.landlordId,
    required this.question,
    this.answer,
    this.status = 'pending',
    this.createdAt,
    this.answeredAt,
  });

  bool get isAnswered => status == 'answered';

  factory ApartmentQueryModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ApartmentQueryModel(
      id: doc.id,
      apartmentId: data['apartmentId'] ?? '',
      apartmentTitle: data['apartmentTitle'],
      tenantId: data['tenantId'] ?? '',
      tenantName: data['tenantName'],
      landlordId: data['landlordId'] ?? '',
      question: data['question'] ?? '',
      answer: data['answer'],
      status: data['status'] ?? 'pending',
      createdAt: parseDate(data['createdAt']),
      answeredAt: parseDate(data['answeredAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'apartmentId': apartmentId,
      if (apartmentTitle != null) 'apartmentTitle': apartmentTitle,
      'tenantId': tenantId,
      if (tenantName != null) 'tenantName': tenantName,
      'landlordId': landlordId,
      'question': question,
      if (answer != null) 'answer': answer,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      if (answeredAt != null) 'answeredAt': Timestamp.fromDate(answeredAt!),
    };
  }
}
