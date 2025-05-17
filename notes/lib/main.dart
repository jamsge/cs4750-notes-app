import 'package:flutter/material.dart';

import 'app.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase Authentication
    try {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      print('Firebase Authentication emulator initialized successfully');
    } catch (authError) {
      print('Error initializing Firebase Authentication emulator: $authError');
      // Fallback to production Firebase Authentication
      print('Switching to production Firebase Authentication...');
    }

    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      print('Firebase Firestore emulator initialized successfully');
    } catch (firestoreError) {
      print('Error initializing Firebase Firestore emulator: $firestoreError');
      print('Switching to production Firestore DB...');
    }


    try {
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      print('Firebase Functions emulator initialized successfully');
    } catch (functionsError) {
      print('Error initializing Firebase Functions emulator: $functionsError');
      print('Switching to production Fucntions...');
    }


    // Set up the SettingsController
    final settingsController = SettingsController(SettingsService());

    // Load settings
    await settingsController.loadSettings();

    // Run the app
    runApp(MyApp(settingsController: settingsController));
  } catch (error) {
    print('Error initializing Firebase: $error');
    // You can handle the error here or show an error message to the user
  }
}
