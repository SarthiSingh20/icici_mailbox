import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/dashboard_screen.dart';

void main() {
  runApp(const ProviderScope(child: IciciMailBoxApp()));
}

class IciciMailBoxApp extends StatelessWidget {
  const IciciMailBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFE77817);

    return MaterialApp(
      title: 'ICICI Mail Box',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
