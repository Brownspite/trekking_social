# Backend Integration TODOs (Hardcoded Elements)

This document tracks all the elements in the UI that are currently hardcoded and need to be wired up to Firebase Firestore or other backend services.

## ~~1. Events Data~~ ✅ DONE
- **Status:** Events are now streamed from Firestore via `EventService`. The `events` collection is auto-seeded on first launch.
- **Files changed:** `event_model.dart`, `event_service.dart` (new), `home_screen.dart`, `calendar_screen.dart`, `main.dart`

## ~~2. User's Joined Events~~ ✅ DONE
- **Status:** `my_events_screen.dart` now fetches the `eventsJoined` array from the user's Firestore document and cross-references with the `events` collection.
- **Files changed:** `my_events_screen.dart`

## ~~3. Profile Statistics~~ ✅ DONE
- **Status:** Stats are computed dynamically from the user's `eventsJoined` array, categorized by event tag (Trekking vs Social).
- **Files changed:** `profile_screen.dart`

## ~~4. "Member Since" Date~~ ✅ DONE
- **Status:** Pulls the `createdAt` timestamp from the user's Firestore document. Falls back to current date if missing.
- **Files changed:** `profile_screen.dart`

## ~~5. User Bio & Avatar~~ ✅ DONE
- **Status:** Bio field added to Firestore user document, Edit Profile screen, and Profile screen display. Avatar still uses initials (no image upload).
- **Files changed:** `auth_service.dart`, `edit_profile_screen.dart`, `profile_screen.dart`

## 6. Payments
- **Location:** `lib/screens/event_detail_screen.dart`
- **Issue:** Events display a price but there is no actual checkout flow or payment gateway installed.
- **Action Required:**
  - Integrate Stripe (or similar) to handle real checkout flows when a user clicks "Join Event" on a paid event.

## 7. Past Events List
- **Location:** `lib/screens/my_events_screen.dart`
- **Issue:** The "Past" tab uses a hardcoded `_pastEvents` list of dummy data.
- **Action Required:**
  - Fetch past events dynamically by filtering the user's `eventsJoined` for events where the date has already passed.
