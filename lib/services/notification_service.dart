import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _userNotifications {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(userId).collection('notifications');
  }

  Stream<List<AppNotification>> getUserNotifications() {
    try {
      return _userNotifications
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    String type = 'general',
    String? eventId,
    String? fromUserId,
  }) async {
    if (targetUserId == _auth.currentUser?.uid) return;

    final notification = AppNotification(
      id: '',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      eventId: eventId,
      fromUserId: fromUserId,
    );

    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('notifications')
        .add(notification.toFirestore());
  }

  Future<void> markAsRead(String notificationId) async {
    await _userNotifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final snapshot = await _userNotifications.where('isRead', isEqualTo: false).get();
    
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }
}
