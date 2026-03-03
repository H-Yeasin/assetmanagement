import 'package:flutter/material.dart';

import 'package:anick_giroux/router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Anick Giroux',
      theme: ThemeData(useMaterial3: true),
      routerConfig: appRouter,
    );
  }
}
