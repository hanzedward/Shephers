import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shepherds_app/firebase_options.dart';
import 'package:shepherds_app/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ShepherdsApp());
}

class ShepherdsApp extends StatelessWidget {
  const ShepherdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Shepherd's Catering & Events",
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF080A0B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD5A021),
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(),
    );
  }
}
