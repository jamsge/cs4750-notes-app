import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'package:flutter/services.dart' show rootBundle;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final databaseService = DatabaseService();

  // Stream to track auth state changes
  Stream<User?> get user => _auth.authStateChanges();

  // Email & Password Sign Up
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);

      try {
        // First create the folder and get its ID
        String folderId = await databaseService.createFolder(
          path: '',
          name: 'My First Folder',
        );
        debugPrint('Created folder with ID: $folderId');


        String markdownContent = await rootBundle.loadString('assets/start-file.md');

        // Then create the note inside that folder
        // The path format is 'folders/folderId' since folders are stored in 'folders' collection
        String noteId = await databaseService.createNote(
          path: 'folders/$folderId',
          name: 'My First Note',
          content: markdownContent
        );
        debugPrint('Created note with ID: $noteId in folder $folderId');
      } catch (e) {
        debugPrint('Error creating first folder or note: $e');
        throw 'An unexpected error occurred';
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('SignUp Error: ${e.code} - ${e.message}');
      throw _authExceptionHandler(e);
    } catch (e) {
      debugPrint('SignUp Error: $e');
      throw 'An unexpected error occurred';
    }
  }

  // Email & Password Sign In
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('SignIn Error: ${e.code} - ${e.message}');
      throw _authExceptionHandler(e);
    } catch (e) {
      debugPrint('SignIn Error: $e');
      throw 'An unexpected error occurred';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password Reset Error: ${e.code} - ${e.message}');
      throw _authExceptionHandler(e);
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      throw 'An unexpected error occurred';
    }
  }

  Future<String?> deleteAccount() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // Note: You might want to require the user to reauthenticate first
        // before deleting the account for security purposes
        await user.delete();
        return null; // Return null on success
      }
      return 'No user is currently signed in';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to delete account';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Change user display name
  Future<String?> changeDisplayName(String newDisplayName) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        await user.updateDisplayName(newDisplayName);
        await user.reload(); // Reload the user to see the changes
        return null; // Return null on success
      }
      return 'No user is currently signed in';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to update display name';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Optional: Reauthenticate user (often needed before sensitive operations)
  Future<String?> reauthenticate(String email, String password) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        return null;
      }
      return 'No user is currently signed in';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Reauthentication failed';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Helper to handle auth exceptions
  String _authExceptionHandler(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is malformed.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
