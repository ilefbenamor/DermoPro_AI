import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart'; // Import de ton nouveau fichier
import 'screens/home/main_navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  runApp(const GeminiSkinApp());
}

class GeminiSkinApp extends StatelessWidget {
  const GeminiSkinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DermoPro AI',
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: const Color(0xFF009688), // Ton Teal médical
      ),
      
      // La logique de démarrage
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          if (snapshot.hasData) {
            // Si le docteur est déjà connecté -> Navigation Principale
            return const MainNavigation();
          } else {
            // Si c'est un nouvel utilisateur ou déconnecté -> Welcome Page
            return const OnboardingScreen();
          }
        },
      ),

      // Définition des routes pour la navigation interne
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigation(),
      },
    );
  }
}