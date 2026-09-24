import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _notificationsRef => _firestore.collection('notifications');

  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String message,
    String? apartmentId,
    String? rentalRequestId,
    String? inquiryId,
    String? maintenanceRequestId,
    String? rentRecordId,
  }) async {
    final cleanRecipient = recipientId.trim();
    if (cleanRecipient.isEmpty) return;

    final docData = <String, dynamic>{
      'recipientId': cleanRecipient,
      'type': type,
      'title': title.trim(),
      'message': message.trim(),
      if (apartmentId != null && apartmentId.trim().isNotEmpty) 'apartmentId': apartmentId.trim(),
      if (rentalRequestId != null && rentalRequestId.trim().isNotEmpty) 'rentalRequestId': rentalRequestId.trim(),
      if (inquiryId != null && inquiryId.trim().isNotEmpty) 'inquiryId': inquiryId.trim(),
      if (maintenanceRequestId != null && maintenanceRequestId.trim().isNotEmpty)
        'maintenanceRequestId': maintenanceRequestId.trim(),
      if (rentRecordId != null && rentRecordId.trim().isNotEmpty) 'rentRecordId': rentRecordId.trim(),
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _notificationsRef.add(docData);
  }

  Stream<List<NotificationModel>> streamUserNotifications(String recipientId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null && user.uid == recipientId) ? user.uid : recipientId;
    if (effectiveId.isEmpty) return Stream.value([]);

    return _notificationsRef
        .where('recipientId', isEqualTo: effectiveId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  Stream<List<NotificationModel>> streamUnreadNotifications(String recipientId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null && user.uid == recipientId) ? user.uid : recipientId;
    if (effectiveId.isEmpty) return Stream.value([]);

    return _notificationsRef
        .where('recipientId', isEqualTo: effectiveId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (_) {}
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';
    await _notificationsRef.doc(notificationId).delete();
  }

  Future<void> clearAllForUser(String recipientId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != recipientId) return;

    final batch = _firestore.batch();
    final query = await _notificationsRef.where('recipientId', isEqualTo: recipientId).get();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
