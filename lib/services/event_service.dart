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
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => TrekEvent.fromFirestore(doc))
          .where((event) => event.dateTime.isAfter(now))
          .toList();
    });
  }

  Future<List<TrekEvent>> getEvents() async {
    final snapshot = await _eventsRef
        .orderBy('dateTime', descending: false)
        .get();
    final now = DateTime.now();
    return snapshot.docs
        .map((doc) => TrekEvent.fromFirestore(doc))
        .where((event) => event.dateTime.isAfter(now))
        .toList();
  }

  Future<void> createEvent(TrekEvent event) async {
    final docRef = _eventsRef.doc();
    await docRef.set(event.toFirestore());
  }

  Future<void> updateEvent(TrekEvent event) async {
    final docRef = _eventsRef.doc(event.id);
    await docRef.update(event.toFirestore());
  }

  Future<void> toggleEventJoin(String eventId, String userId, bool isJoining, Map<String, dynamic> attendeeMap) async {
    final eventRef = _eventsRef.doc(eventId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final eventDoc = await transaction.get(eventRef);
      if (!eventDoc.exists) {
        throw Exception("Event does not exist.");
      }

      final data = eventDoc.data() as Map<String, dynamic>;
      final spots = data['spots'] as int? ?? 0;
      final maxSpots = data['maxSpots'] as int? ?? 1;

      if (isJoining) {
        if (spots >= maxSpots) {
          throw Exception("Event is full");
        }
        transaction.update(eventRef, {
          'spots': spots + 1,
          'attendees': FieldValue.arrayUnion([attendeeMap])
        });
        transaction.update(userRef, {
          'eventsJoined': FieldValue.arrayUnion([eventId])
        });
      } else {
        transaction.update(eventRef, {
          'spots': (spots - 1).clamp(0, maxSpots),
          'attendees': FieldValue.arrayRemove([attendeeMap])
        });
        transaction.update(userRef, {
          'eventsJoined': FieldValue.arrayRemove([eventId])
        });
      }
    });
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
