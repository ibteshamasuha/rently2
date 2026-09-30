import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/apartment_model.dart';

class ApartmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _apartmentsRef => _firestore.collection('apartments');

  /// Stream of all publicly discoverable apartments for tenant browsing
  Stream<List<ApartmentModel>> getAvailableApartments() {
    return _apartmentsRef
        .where('status', whereIn: ['available', 'Available'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentModel.fromFirestore(doc))
            .toList());
  }

  /// Tenant apartment listings discovery stream (all published available apartments)
  Stream<List<ApartmentModel>> getAllApartments() {
    return _apartmentsRef
        .where('status', whereIn: ['available', 'Available'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentModel.fromFirestore(doc))
            .toList());
  }

  /// Scoped stream for a landlord's own apartments
  Stream<List<ApartmentModel>> getLandlordApartments(String landlordId) {
    return _apartmentsRef
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentModel.fromFirestore(doc))
            .toList());
  }

  /// Scoped stream for a tenant's rented apartments
  Stream<List<ApartmentModel>> getTenantApartments(String tenantId) {
    return _apartmentsRef
        .where('currentTenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentModel.fromFirestore(doc))
            .where((a) => a.isRented) // Ensure only currently rented ones show up
            .toList());
  }

  Future<ApartmentModel?> getApartmentById(String apartmentId) async {
    try {
      final doc = await _apartmentsRef.doc(apartmentId).get();
      if (doc.exists && doc.data() != null) {
        return ApartmentModel.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }

  /// Live stream for a specific apartment document by its ID
  Stream<ApartmentModel?> streamApartment(String apartmentId) {
    return _apartmentsRef.doc(apartmentId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return ApartmentModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Create apartment strictly bound to the authenticated landlord UID
  Future<void> createApartment(ApartmentModel apartment) async {
    final effectiveLandlordId = _auth.currentUser?.uid ??
        (apartment.landlordId.trim().isNotEmpty ? apartment.landlordId.trim() : null);
    if (effectiveLandlordId == null) throw 'User not authenticated.';

    final map = apartment.toMap();
    // Enforce authenticated landlord UID regardless of client payload
    map['landlordId'] = effectiveLandlordId;

    await _apartmentsRef.add(map);
  }

  /// Update apartment strictly bound to the authenticated landlord UID
  Future<void> updateApartment(ApartmentModel apartment) async {
    final effectiveLandlordId = _auth.currentUser?.uid ??
        (apartment.landlordId.trim().isNotEmpty ? apartment.landlordId.trim() : null);
    if (effectiveLandlordId == null) throw 'User not authenticated.';

    final map = apartment.toMap();
    // Ensure landlordId cannot be reassigned to another landlord
    map['landlordId'] = effectiveLandlordId;

    await _apartmentsRef.doc(apartment.id).update(map);
  }

  Future<void> updateApartmentStatus(String apartmentId, String status) async {
    await _apartmentsRef.doc(apartmentId).update({'status': status});
  }

  Future<void> deleteApartment(String apartmentId) async {
    await _apartmentsRef.doc(apartmentId).delete();
  }
}
