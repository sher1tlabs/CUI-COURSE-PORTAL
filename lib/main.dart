import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for seamless monochrome appearance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Bootstrap initial catalogue data if Firestore is empty
    await FirestoreService.instance.initializePortalDataIfEmpty();
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(const ComsatsPortalApp());
}
