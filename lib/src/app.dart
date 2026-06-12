import 'package:flutter/material.dart';

import 'ui/home/home_screen.dart';

class DonorApp extends StatelessWidget {
  const DonorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1B873B));
    return MaterialApp(
      title: 'Donor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        // Flat, soft-cornered surfaces everywhere instead of per-widget
        // styling — change the look in one place.
        cardTheme: CardThemeData(
          elevation: 0,
          color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF103D20),
            letterSpacing: -0.5,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
