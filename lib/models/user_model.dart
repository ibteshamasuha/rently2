import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'tenant', 'landlord', 'both', 'admin'
  final String? phone;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.createdAt,
  });

  bool get isTenant => role == 'tenant' || role == 'both';
  bool get isLandlord => role == 'landlord' || role == 'both';
  bool get isBoth => role == 'both';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    DateTime? parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt']);
    }

    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'tenant',
      phone: data['phone'],
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
