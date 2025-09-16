import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:kampus_kart/widgets/nav_rail.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Shows Page after the Splash screen
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KampusKart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 92, 241, 124)),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          FlutterNativeSplash.remove();

          Widget targetPage = 
            snapshot.hasData ? const MyNavRail() : const LoginPage();

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
            child: targetPage,
          );
        },
      ),
    );
  }
}