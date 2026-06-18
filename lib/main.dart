import 'dart:io' show Platform;

import 'package:ffp_vault/Loan_Screen/models/document_model.dart';
import 'package:ffp_vault/Loan_Screen/models/loan_model.dart';
import 'package:ffp_vault/app.dart';
import 'package:ffp_vault/config/app_config.dart';
import 'package:ffp_vault/firebase_options.dart';
import 'package:ffp_vault/services/notification_service.dart';
import 'package:ffp_vault/services/revenuecat_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kDebugMode || AppConfig.useFirebaseAppCheck) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttest,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // ── RevenueCat: initialize the SDK ──────────────────────────────────────
  await _initRevenueCat();

  // ── RevenueCat: keep Firestore in sync with purchase events ─────────────
  RevenueCatService().listenForCustomerInfoUpdates();

  await Hive.initFlutter();
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(DocumentFileAdapter());

  // Non-blocking initialization to avoid white screen hang
  NotificationService.init().then((_) {
    NotificationService.initFCM();
  });

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initRevenueCat() async {
  // Resolve the API key: unified key first, then platform-specific fallback.
  final apiKey = _resolveRcApiKey();
  if (apiKey.isEmpty) {
    debugPrint(
      'RevenueCat SDK not configured — skipping initialization. '
      'Set RC_API_KEY (or RC_APPLE_API_KEY / RC_GOOGLE_API_KEY) via --dart-define.',
    );
    return;
  }

  try {
    await Purchases.configure(PurchasesConfiguration(apiKey));
    debugPrint('RevenueCat SDK initialized successfully.');
  } catch (e) {
    debugPrint('RevenueCat initialization error: $e');
    return; // Don't continue if configuration failed.
  }

  // Auto-login the current Firebase user (if already signed in) so the RC SDK
  // can associate purchases with this account.
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await RevenueCatService().login();
      debugPrint('RevenueCat login succeeded.');
    } catch (e) {
      debugPrint('RevenueCat login error: $e');
    }
  }

  // Keep RC logged-in identity in sync with Firebase auth state.
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      RevenueCatService().login().then(
        (_) {},
        onError: (e) => debugPrint('RevenueCat login error on auth change: $e'),
      );
    } else {
      RevenueCatService().logout().then(
        (_) {},
        onError: (e) => debugPrint('RevenueCat logout error: $e'),
      );
    }
  });
}

/// Picks the best available RevenueCat API key.
///
/// Priority: unified `RC_API_KEY` > platform-specific pair.
String _resolveRcApiKey() {
  // Unified key (RevenueCat v5+)
  if (AppConfig.rcApiKey.isNotEmpty) {
    return AppConfig.rcApiKey;
  }

  // Platform-specific keys
  return Platform.isIOS
      ? AppConfig.revenueCatAppleApiKey
      : AppConfig.revenueCatGoogleApiKey;
}
