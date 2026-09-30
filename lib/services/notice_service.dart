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
          .where((n) => !n.hiddenBy.contains(effectiveId))
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  /// Tenants see public announcements and notices specifically intended for them or their rented apartments (Issue 17 & Requirement 5)
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
        // 1. Notices targeted to this specific tenant by targetTenantId
        final targetedSnap = await _noticesRef
            .where('targetTenantId', isEqualTo: effectiveId)
            .get();
        final targetedNotices = targetedSnap.docs
            .map((doc) => NoticeModel.fromFirestore(doc))
            .toList();

        // 2. Notices targeted by tenantId field
        final tenantIdSnap = await _noticesRef
            .where('tenantId', isEqualTo: effectiveId)
            .get();
        final tenantIdNotices = tenantIdSnap.docs
            .map((doc) => NoticeModel.fromFirestore(doc))
            .toList();

        // 3. Notices targeted to the tenant's rented apartment(s) and finding landlords
        final aptNotices = <NoticeModel>[];
        final landlordIds = <String>{};
        try {
          final userAptsSnap = await _firestore
              .collection('apartments')
              .where('currentTenantId', isEqualTo: effectiveId)
              .get();

          for (final aptDoc in userAptsSnap.docs) {
            final landlordId = aptDoc.data()['landlordId'] as String?;
            if (landlordId != null) {
              landlordIds.add(landlordId);
            }
            
            final aSnap = await _noticesRef
                .where('apartmentId', isEqualTo: aptDoc.id)
                .get();
            aptNotices.addAll(aSnap.docs.map((d) => NoticeModel.fromFirestore(d)));
          }
        } catch (_) {}

        final filteredPublicNotices = publicNotices.where((n) {
          return n.authorRole == 'admin' || landlordIds.contains(n.authorId);
        }).toList();

        final all = <String, NoticeModel>{};
        for (final n in [...filteredPublicNotices, ...targetedNotices, ...tenantIdNotices, ...aptNotices]) {
          if (!n.hiddenBy.contains(effectiveId)) {
            all[n.id] = n;
          }
        }
        final list = all.values.toList();
        list.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        return list;
      } catch (_) {
        return [];
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
    String? tenantId,
    String? apartmentId,
    String? targetType,
  }) async {
    final user = _auth.currentUser;
    final effectiveAuthorId = user != null ? user.uid : authorId;
    final effectiveTenantId = targetTenantId?.trim() ?? tenantId?.trim();
    final effectiveApartmentId = apartmentId?.trim();

    final effectiveTargetType = targetType ??
        (effectiveTenantId != null && effectiveTenantId.isNotEmpty
            ? 'tenant'
            : (effectiveApartmentId != null && effectiveApartmentId.isNotEmpty ? 'apartment' : 'all'));

    // Targeted notices are private to the intended recipient/apartment
    final effectiveIsPublic = effectiveTargetType == 'all' ? isPublic : false;
    
    List<String> targetTenantIds = [];
    if (effectiveTargetType == 'all' && authorRole != 'admin' && authorRole != 'Admin') {
      try {
        final aptsSnap = await _firestore
            .collection('apartments')
            .where('landlordId', isEqualTo: effectiveAuthorId)
            .get();
        for (var doc in aptsSnap.docs) {
          final tid = doc.data()['currentTenantId'] as String?;
          if (tid != null && tid.isNotEmpty) {
            targetTenantIds.add(tid);
          }
        }
      } catch (_) {}
    }

    final notice = NoticeModel(
      id: '',
      title: title.trim(),
      message: message.trim(),
      authorId: effectiveAuthorId,
      authorName: authorName,
      authorRole: authorRole,
      isPublic: effectiveIsPublic,
      targetTenantId: effectiveTenantId,
      targetTenantIds: targetTenantIds.isNotEmpty ? targetTenantIds : null,
      apartmentId: effectiveApartmentId,
      targetType: effectiveTargetType,
      createdAt: DateTime.now(),
    );

    await _noticesRef.add(notice.toMap());

    // Send notifications to all relevant tenants so InAppNotificationPopup triggers
    final Set<String> recipients = {};
    
    if (effectiveTenantId != null && effectiveTenantId.isNotEmpty) {
      recipients.add(effectiveTenantId);
    }
    
    if (targetTenantIds.isNotEmpty) {
      recipients.addAll(targetTenantIds);
    }
    
    if (effectiveApartmentId != null && effectiveApartmentId.isNotEmpty && effectiveTargetType == 'apartment') {
      try {
        final aptDoc = await _firestore.collection('apartments').doc(effectiveApartmentId).get();
        final tid = aptDoc.data()?['currentTenantId'] as String?;
        if (tid != null && tid.isNotEmpty) recipients.add(tid);
      } catch (_) {}
    }
    
    for (final recipientId in recipients) {
      try {
        await _notificationService.createNotification(
          recipientId: recipientId,
          type: 'notice',
          title: 'New Notice: ${title.trim()}',
          message: message.trim(),
          apartmentId: effectiveApartmentId,
        );
      } catch (_) {}
    }
  }

  Future<void> hideNotice(String noticeId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';
    await _noticesRef.doc(noticeId).update({
      'hiddenBy': FieldValue.arrayUnion([user.uid])
    });
  }

  Future<void> deleteNotice(String noticeId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';
    await _noticesRef.doc(noticeId).delete();
  }
}
