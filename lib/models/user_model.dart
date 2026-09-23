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

  String get normalizedRole => role.trim().toLowerCase();

  bool get isTenant => normalizedRole == 'tenant' || normalizedRole == 'both';
  bool get isLandlord => normalizedRole == 'landlord' || normalizedRole == 'both';
  bool get isBoth => normalizedRole == 'both';
  bool get isAdmin => normalizedRole == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    DateTime? parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt']);
    }

    final rawRole = (data['role'] as String?)?.trim().toLowerCase() ?? 'tenant';

    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: rawRole,
      phone: data['phone'],
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': normalizedRole,
      'phone': phone,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
