import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notice_model.dart';
import 'notification_service.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference get _noticesRef => _firestore.collection('notices');

  /// Landlords see only the notices they published (Requirement 2 & Issue 17)
  Stream<List<NoticeModel>> getLandlordNotices(String landlordId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null && user.uid == landlordId) ? user.uid : landlordId;
    return _noticesRef
        .where('authorId', isEqualTo: effectiveId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NoticeModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  /// Tenants see public announcements and notices specifically intended for them (Issue 17)
  Stream<List<NoticeModel>> getTenantNotices(String tenantId) {
    final user = _auth.currentUser;
    final effectiveId = (user != null) ? user.uid : tenantId;
    if (effectiveId.isEmpty) return Stream.value([]);

    return _noticesRef
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .asyncMap((publicSnap) async {
      final publicNotices = publicSnap.docs
          .map((doc) => NoticeModel.fromFirestore(doc))
          .toList();

      try {
        final targetedSnap = await _noticesRef
            .where('targetTenantId', isEqualTo: effectiveId)
            .get();
        final targetedNotices = targetedSnap.docs
            .map((doc) => NoticeModel.fromFirestore(doc))
            .toList();

        final all = <String, NoticeModel>{};
        for (final n in [...publicNotices, ...targetedNotices]) {
          all[n.id] = n;
        }
        final list = all.values.toList();
        list.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        return list;
      } catch (_) {
        return publicNotices;
      }
    });
  }

  /// General getNotices for admin or system overview
  Stream<List<NoticeModel>> getNotices() {
    return _noticesRef.where('isPublic', isEqualTo: true).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NoticeModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  Future<void> createNotice({
    required String title,
    required String message,
    required String authorId,
    String? authorName,
    String? authorRole,
    bool isPublic = true,
    String? targetTenantId,
    String? apartmentId,
  }) async {
    final user = _auth.currentUser;
    final effectiveAuthorId = user != null ? user.uid : authorId;

    final notice = NoticeModel(
      id: '',
      title: title.trim(),
      message: message.trim(),
      authorId: effectiveAuthorId,
      authorName: authorName,
      authorRole: authorRole,
      isPublic: isPublic,
      targetTenantId: targetTenantId?.trim(),
      apartmentId: apartmentId?.trim(),
      createdAt: DateTime.now(),
    );

    await _noticesRef.add(notice.toMap());

    // If targeted to a specific tenant, deliver notification (Issue 6 & 17)
    if (targetTenantId != null && targetTenantId.trim().isNotEmpty) {
      try {
        await _notificationService.createNotification(
          recipientId: targetTenantId.trim(),
          type: 'notice',
          title: 'New Notice: ${title.trim()}',
          message: message.trim(),
          apartmentId: apartmentId?.trim(),
        );
      } catch (_) {}
    }
  }

  Future<void> deleteNotice(String noticeId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';
    await _noticesRef.doc(noticeId).delete();
  }
}
