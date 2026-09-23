import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/apartment_model.dart';

class ApartmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _apartmentsRef => _firestore.collection('apartments');

  Stream<List<ApartmentModel>> getAvailableApartments() {
    return _apartmentsRef
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentModel.fromFirestore(doc))
            .where((apt) => apt.isAvailable)
            .toList());
  }

  Stream<List<ApartmentModel>> getAllApartments() {
    return _apartmentsRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ApartmentModel.fromFirestore(doc)).toList());
  }

  Stream<List<ApartmentModel>> getLandlordApartments(String landlordId) {
    return _apartmentsRef
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApartmentModel.fromFirestore(doc))
            .toList());
  }

  Future<ApartmentModel?> getApartmentById(String apartmentId) async {
    final doc = await _apartmentsRef.doc(apartmentId).get();
    if (!doc.exists) return null;
    return ApartmentModel.fromFirestore(doc);
  }

  Future<void> createApartment(ApartmentModel apartment) async {
    await _apartmentsRef.add(apartment.toMap());
  }

  Future<void> updateApartment(ApartmentModel apartment) async {
    await _apartmentsRef.doc(apartment.id).update(apartment.toMap());
  }

  Future<void> updateApartmentStatus(String apartmentId, String status) async {
    await _apartmentsRef.doc(apartmentId).update({'status': status});
  }

  Future<void> deleteApartment(String apartmentId) async {
    await _apartmentsRef.doc(apartmentId).delete();
  }
}
