import 'package:flutter/material.dart';
import 'main_screen.dart';

void main() {
  runApp(const KompromisApp());
}

class KompromisApp extends StatelessWidget {
  const KompromisApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kompromis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          surface: Color(0xFF1A1A1A),
        ),
      ),
      home: MainScreen(),
    );
  }
}