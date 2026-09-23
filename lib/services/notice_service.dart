import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notice_model.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _noticesRef => _firestore.collection('notices');

  /// Landlords see only the notices they published (Requirement 2)
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

  /// Tenants see public announcements and notices specifically intended for them
  Stream<List<NoticeModel>> getTenantNotices(String tenantId) {
    return _noticesRef
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NoticeModel.fromFirestore(doc))
          .where((n) => n.isPublic || n.targetTenantId == tenantId)
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  /// General getNotices with backward compatibility
  Stream<List<NoticeModel>> getNotices() {
    return _noticesRef.snapshots().map((snapshot) {
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
      title: title,
      message: message,
      authorId: effectiveAuthorId,
      authorName: authorName,
      authorRole: authorRole,
      isPublic: isPublic,
      targetTenantId: targetTenantId,
      apartmentId: apartmentId,
      createdAt: DateTime.now(),
    );

    await _noticesRef.add(notice.toMap());
  }

  Future<void> deleteNotice(String noticeId) async {
    await _noticesRef.doc(noticeId).delete();
  }
}
