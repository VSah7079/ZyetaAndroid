import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const ZyetaWorkforceApp());
}

class ZyetaWorkforceApp extends StatelessWidget {
  const ZyetaWorkforceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZyetaGate OS Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
