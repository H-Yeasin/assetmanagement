import 'package:flutter/material.dart';

import 'package:ffp_vault/router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FFP Vault',
      theme: ThemeData(useMaterial3: true),
      routerConfig: appRouter,
    );
  }
}
