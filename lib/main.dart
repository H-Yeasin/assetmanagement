import 'package:anick_giroux/app.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:anick_giroux/Loan_Screen/models/loan_model.dart';
import 'package:anick_giroux/Loan_Screen/models/document_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:anick_giroux/firebase_options.dart';
import 'package:anick_giroux/services/notification_service.dart';
import 'package:anick_giroux/services/subscription_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.urlScheme = 'anickgiroux';
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize App Check to unblock Storage uploads on simulator/emulator
    FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  await Hive.initFlutter();
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(DocumentFileAdapter());

  // Non-blocking initialization to avoid white screen hang
  NotificationService.init().then((_) {
    NotificationService.initFCM();
  });

  // Preload Stripe config so PaymentSheet can open with a ready publishable key.
  SubscriptionService().ensureStripeConfigured().catchError((error) {
    debugPrint('Stripe initialization skipped: $error');
  });

  runApp(const ProviderScope(child: MyApp()));
}
