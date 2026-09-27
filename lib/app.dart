import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';

class ComsatsPortalApp extends StatefulWidget {
  const ComsatsPortalApp({super.key});

  @override
  State<ComsatsPortalApp> createState() => _ComsatsPortalAppState();
}

class _ComsatsPortalAppState extends State<ComsatsPortalApp> {
  ThemeMode _themeMode = ThemeMode.dark; // Default to sleek premium dark minimal

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COMSATS Student Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: const WelcomeScreen(),
    );
  }
}
