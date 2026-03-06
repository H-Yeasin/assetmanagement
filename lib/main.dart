import 'package:anick_giroux/app.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:anick_giroux/Loan_Screen/models/loan_model.dart';
import 'package:anick_giroux/Loan_Screen/models/document_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:anick_giroux/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  await Hive.initFlutter();
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(DocumentFileAdapter());

  runApp(const ProviderScope(child: MyApp()));
}
