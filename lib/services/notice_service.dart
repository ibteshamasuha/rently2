import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _noticesRef => _firestore.collection('notices');

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
  }) async {
    final notice = NoticeModel(
      id: '',
      title: title,
      message: message,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      createdAt: DateTime.now(),
    );

    await _noticesRef.add(notice.toMap());
  }

  Future<void> deleteNotice(String noticeId) async {
    await _noticesRef.doc(noticeId).delete();
  }
}
