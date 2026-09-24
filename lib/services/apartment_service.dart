import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/mock_apartments.dart';
import '../models/apartment_model.dart';

class ApartmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _apartmentsRef => _firestore.collection('apartments');

  /// Stream of all publicly available apartments for tenant discovery (Firestore + Catalog)
  Stream<List<ApartmentModel>> getAvailableApartments() {
    return _apartmentsRef.snapshots().map((snapshot) {
      final firestoreList = snapshot.docs
          .map((doc) => ApartmentModel.fromFirestore(doc))
          .toList();
      final firestoreIds = firestoreList.map((a) => a.id).toSet();

      // Filter catalog to those not overridden in Firestore and available
      final catalogAvailable = kCatalogApartments
          .where((a) => !firestoreIds.contains(a.id) && a.isAvailable)
          .toList();

      return [...firestoreList.where((a) => a.isAvailable), ...catalogAvailable];
    });
  }

  /// Tenant apartment listings discovery stream (available apartments)
  Stream<List<ApartmentModel>> getAllApartments() {
    return _apartmentsRef.snapshots().map((snapshot) {
      final firestoreList = snapshot.docs
          .map((doc) => ApartmentModel.fromFirestore(doc))
          .toList();
      final firestoreIds = firestoreList.map((a) => a.id).toSet();

      final catalogRemaining = kCatalogApartments
          .where((a) => !firestoreIds.contains(a.id))
          .toList();

      return [...firestoreList, ...catalogRemaining];
    });
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
      if (doc.exists && doc.data() != null) {
        return ApartmentModel.fromFirestore(doc);
      }
    } catch (_) {}

    // Check catalog fallback
    for (final apt in kCatalogApartments) {
      if (apt.id == apartmentId) return apt;
    }
    return null;
  }

  /// Live stream for a specific apartment document by its ID
  Stream<ApartmentModel?> streamApartment(String apartmentId) {
    return _apartmentsRef.doc(apartmentId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return ApartmentModel.fromFirestore(doc);
      }
      for (final apt in kCatalogApartments) {
        if (apt.id == apartmentId) return apt;
      }
      return null;
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
