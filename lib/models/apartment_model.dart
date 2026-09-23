import 'package:cloud_firestore/cloud_firestore.dart';

class ApartmentModel {
  final String id;
  final String title;
  final String location;
  final num rent;
  final String status; // 'available', 'rented'
  final String description;
  final String landlordId;
  final DateTime? createdAt;

  ApartmentModel({
    required this.id,
    required this.title,
    required this.location,
    required this.rent,
    required this.status,
    required this.description,
    required this.landlordId,
    this.createdAt,
  });

  bool get isAvailable => status.toLowerCase() == 'available';

  factory ApartmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime? parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt']);
    }

    return ApartmentModel(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      rent: data['rent'] ?? 0,
      status: data['status'] ?? 'available',
      description: data['description'] ?? '',
      landlordId: data['landlordId'] ?? '',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'rent': rent,
      'status': status,
      'description': description,
      'landlordId': landlordId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
