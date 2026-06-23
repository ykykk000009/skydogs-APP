import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../ui/screens/home_screen.dart';

class SkyDogsApp extends StatelessWidget {
  const SkyDogsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyDogs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
