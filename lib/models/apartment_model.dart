import 'package:cloud_firestore/cloud_firestore.dart';

class ApartmentModel {
  final String id;
  final String title;
  final String location;
  final num rent;
  final String status; // 'available', 'pending', 'rented'
  final String description;
  final String landlordId;
  final int bedrooms;
  final int bathrooms;
  final int areaSqFt;
  final List<String> images;
  final List<String> features;
  final List<String> amenities;
  final DateTime? createdAt;

  ApartmentModel({
    required this.id,
    required this.title,
    required this.location,
    required this.rent,
    required this.status,
    required this.description,
    required this.landlordId,
    this.bedrooms = 2,
    this.bathrooms = 1,
    this.areaSqFt = 900,
    this.images = const [],
    this.features = const [],
    this.amenities = const [],
    this.createdAt,
  });

  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRented => status.toLowerCase() == 'rented';

  factory ApartmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime? parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt']);
    }

    List<String> parsedImages = [];
    if (data['images'] is List) {
      parsedImages = List<String>.from(data['images']);
    } else if (data['imageUrl'] is String && (data['imageUrl'] as String).isNotEmpty) {
      parsedImages = [data['imageUrl'] as String];
    }

    List<String> parsedFeatures = [];
    if (data['features'] is List) {
      parsedFeatures = (data['features'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<String> parsedAmenities = [];
    if (data['amenities'] is List) {
      parsedAmenities = (data['amenities'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return ApartmentModel(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? 'Rajshahi',
      rent: data['rent'] ?? 0,
      status: data['status'] ?? 'available',
      description: data['description'] ?? '',
      landlordId: data['landlordId'] ?? '',
      bedrooms: data['bedrooms'] ?? 2,
      bathrooms: data['bathrooms'] ?? 1,
      areaSqFt: data['areaSqFt'] ?? 900,
      images: parsedImages,
      features: parsedFeatures,
      amenities: parsedAmenities,
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
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'areaSqFt': areaSqFt,
      if (images.isNotEmpty) 'images': images,
      'features': features,
      'amenities': amenities,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
