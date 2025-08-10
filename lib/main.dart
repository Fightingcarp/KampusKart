import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'pages/login_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Main function of the App
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initialization();
  }

  // Launches Splash Screen
  void initialization() async {
    print('pausing....');
    await Future.delayed(const Duration(milliseconds: 1000));
    print('unpausing....');
    FlutterNativeSplash.remove();
  }

  // Calls login page after the Splash screen
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'KampusKart',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 92, 241, 124)),
        ),
        home: LoginPage(),
    );
  }
}