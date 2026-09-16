
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tawafuq/pages/FirstScreen.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

     try {
       await Firebase.initializeApp();
     } catch (e) {
     }
     
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tawafuq',
      theme: defaultTheme,
      home: const Firstscreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
