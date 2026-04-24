import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _eventsRef => _firestore.collection('events');

  Stream<List<TrekEvent>> streamEvents() {
    return _eventsRef
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TrekEvent.fromFirestore(doc)).toList();
    });
  }

  Future<List<TrekEvent>> getEvents() async {
    final snapshot =
        await _eventsRef.orderBy('dateTime', descending: false).get();
    return snapshot.docs.map((doc) => TrekEvent.fromFirestore(doc)).toList();
  }

  Future<void> createEvent(TrekEvent event) async {
    final docRef = _eventsRef.doc();
    await docRef.set(event.toFirestore());
  }

  Future<void> toggleEventJoin(String eventId, String userId, bool isJoining, Map<String, dynamic> attendeeMap) async {
    final eventRef = _eventsRef.doc(eventId);
    final userRef = _firestore.collection('users').doc(userId);

    final batch = _firestore.batch();

    if (isJoining) {
      batch.update(eventRef, {
        'spots': FieldValue.increment(1),
        'attendees': FieldValue.arrayUnion([attendeeMap])
      });
      batch.update(userRef, {
        'eventsJoined': FieldValue.arrayUnion([eventId])
      });
    } else {
      batch.update(eventRef, {
        'spots': FieldValue.increment(-1),
        'attendees': FieldValue.arrayRemove([attendeeMap])
      });
      batch.update(userRef, {
        'eventsJoined': FieldValue.arrayRemove([eventId])
      });
    }

    await batch.commit();
  }

  Future<void> seedEvents() async {
    final existing = await _eventsRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final event in TrekEvent.sampleEvents()) {
      final docRef = _eventsRef.doc();
      batch.set(docRef, event.toFirestore());
    }
    await batch.commit();
  }
}
