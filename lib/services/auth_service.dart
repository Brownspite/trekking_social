import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> registerWithEmailAndPassword({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await result.user?.updateDisplayName(fullName);

      await _firestore.collection('users').doc(result.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'bio': '',
        'avatarId': 0,
        'pushEnabled': true,
        'emailEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'eventsJoined': [],
      });

      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _getErrorMessage(e.code, e.message);
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error: ${e.code} - ${e.message}');
      throw _getErrorMessage(e.code, e.message);
    } catch (e) {
      debugPrint('General Registration Error: $e');
      throw 'Registration failed. Please try again.';
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting sign in for: $email');
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Sign in successful: ${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Sign-In Error: ${e.code} - ${e.message}');
      throw _getErrorMessage(e.code, e.message);
    } on FirebaseException catch (e) {
      debugPrint('Firebase Sign-In Error: ${e.code} - ${e.message}');
      throw _getErrorMessage(e.code, e.message);
    } catch (e) {
      debugPrint('General Sign-In Error: $e');
      throw 'Sign in failed. Please try again.';
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      UserCredential result;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        result = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleSignIn = GoogleSignIn(
          clientId: '82918405342-l4t5aeiscunco0vgnctll3i4t3th8sei.apps.googleusercontent.com',
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          throw 'Google sign-in was cancelled.';
        }

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );

        result = await _auth.signInWithCredential(credential);
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'fullName': result.user?.displayName ?? '',
          'email': result.user?.email ?? '',
          'bio': '',
          'avatarId': 0,
          'pushEnabled': true,
          'emailEnabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'eventsJoined': [],
        });
      }

      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In Auth Error: ${e.code} - ${e.message}');
      throw _getErrorMessage(e.code, e.message);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (e is String) rethrow;
      throw 'Google sign-in failed. Please try again.';
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password Reset Error: ${e.code} - ${e.message}');
      throw _getErrorMessage(e.code, e.message);
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      throw 'Failed to send reset email. Please try again.';
    }
  }

  Future<void> updateProfile({String? fullName, String? bio, int? avatarId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user signed in.';

      final Map<String, dynamic> updates = {};

      if (fullName != null && fullName.trim().isNotEmpty) {
        await user.updateDisplayName(fullName.trim());
        updates['fullName'] = fullName.trim();
      }

      if (bio != null) {
        updates['bio'] = bio.trim();
      }

      if (avatarId != null) {
        updates['avatarId'] = avatarId;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }

      await user.reload();
    } on FirebaseException catch (e) {
      debugPrint('Profile Update Error: ${e.code} - ${e.message}');
      throw _getErrorMessage(e.code, e.message);
    } catch (e) {
      debugPrint('Profile Update Error: $e');
      if (e is String) rethrow;
      throw 'Failed to update profile. Please try again.';
    }
  }

  Future<void> updateNotificationPreferences(bool pushEnabled, bool emailEnabled) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user signed in.';

      await _firestore.collection('users').doc(user.uid).update({
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
      });
    } on FirebaseException catch (e) {
      debugPrint('Notification Update Error: ${e.code} - ${e.message}');
      throw _getErrorMessage(e.code, e.message);
    } catch (e) {
      debugPrint('Notification Update Error: $e');
      throw 'Failed to update preferences. Please try again.';
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().disconnect();
    } catch (_) {}
    await _auth.signOut();
  }

  String _getErrorMessage(String code, String? fallback) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      default:
        return fallback ?? 'An error occurred. Please try again.';
    }
  }
}

