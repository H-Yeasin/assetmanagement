import 'package:anick_giroux/app.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:anick_giroux/Loan_Screen/models/loan_model.dart';
import 'package:anick_giroux/Loan_Screen/models/document_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:anick_giroux/firebase_options.dart';
import 'package:anick_giroux/services/notification_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      'pk_test_51RVRsRFxx6GHySDfLZIuLy002ZBfusrV5YuBtoxr2PbWi0AqYMPRn03xtQAf6u31U3PbUqC8zwkO6XYCypIa0VJt00iLx7IDJ7';
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize App Check to unblock Storage uploads on simulator/emulator
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  await Hive.initFlutter();
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(DocumentFileAdapter());

  await NotificationService.init();
  await NotificationService.initFCM();

  runApp(const ProviderScope(child: MyApp()));
}
