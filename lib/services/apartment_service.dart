import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/apartment_model.dart';

class ApartmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _apartmentsRef => _firestore.collection('apartments');

  /// Stream of all publicly available / published apartments for tenant discovery
  Stream<List<ApartmentModel>> getAvailableApartments() {
    return _apartmentsRef
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentModel.fromFirestore(doc))
            .toList());
  }

  /// Tenant apartment listings discovery stream (available apartments)
  Stream<List<ApartmentModel>> getAllApartments() {
    return _apartmentsRef
        .where('status', isEqualTo: 'available')
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

  Future<ApartmentModel?> getApartmentById(String apartmentId) async {
    try {
      final doc = await _apartmentsRef.doc(apartmentId).get();
      if (!doc.exists) return null;
      return ApartmentModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  /// Live stream for a specific apartment document by its Firestore document ID
  Stream<ApartmentModel?> streamApartment(String apartmentId) {
    return _apartmentsRef.doc(apartmentId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ApartmentModel.fromFirestore(doc);
    });
  }

  /// Create apartment strictly bound to the authenticated landlord UID
  Future<void> createApartment(ApartmentModel apartment) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    final map = apartment.toMap();
    // Enforce authenticated landlord UID regardless of client payload
    map['landlordId'] = user.uid;

    await _apartmentsRef.add(map);
  }

  /// Update apartment strictly bound to the authenticated landlord UID
  Future<void> updateApartment(ApartmentModel apartment) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    final map = apartment.toMap();
    // Ensure landlordId cannot be reassigned to another landlord
    map['landlordId'] = user.uid;

    await _apartmentsRef.doc(apartment.id).update(map);
  }

  Future<void> updateApartmentStatus(String apartmentId, String status) async {
    await _apartmentsRef.doc(apartmentId).update({'status': status});
  }

  Future<void> deleteApartment(String apartmentId) async {
    await _apartmentsRef.doc(apartmentId).delete();
  }
}
