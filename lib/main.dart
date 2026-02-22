import 'package:anick_giroux/app.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:anick_giroux/Loan_Screen/models/loan_model.dart';
import 'package:anick_giroux/Loan_Screen/models/document_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(DocumentFileAdapter());

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

