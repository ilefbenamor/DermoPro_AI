import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gemini_skin_check/screens/home/ailab_screen.dart';
import '../auth/login_screen.dart'; // Assure-toi que ce fichier existe
import 'PatientListScreen.dart'; // Assure-toi que ce fichier existe

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // LISTE DES PAGES
  final List<Widget> _pages = [
    const PatientListScreen(), // Index 0: Accueil (Liste patients)
    const AiLabMainScreen(), // Index 1: Historique (Définie plus bas)
    const ProfileScreen(), // Index 2: Profil (Définie plus bas)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F6),
      extendBody: true, // Permet à la liste de passer derrière la barre de nav
      body: Stack(
        children: [
          // AFFICHE LA PAGE SÉLECTIONNÉE
          // Utilise IndexedStack pour garder l'état des pages (évite de recharger)
          IndexedStack(index: _currentIndex, children: _pages),

          // BARRE DE NAVIGATION FLOTTANTE
          Positioned(
            left: 20,
            right: 20,
            bottom: 25,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF009688).withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.people_alt_outlined, 0, "Patients"),
                  _buildNavItem(Icons.history_edu, 1, "History"),
                  _buildNavItem(Icons.manage_accounts_outlined, 2, "Profile"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 10,
          vertical: 10,
        ),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFF009688), // Teal Pro
                borderRadius: BorderRadius.circular(25),
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 26,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- ECRAN PROFIL (Intégré ici pour simplifier) ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F6),
      appBar: AppBar(
        title: const Text(
          "Doctor Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF009688),
        elevation: 0,
        automaticallyImplyLeading:
            false, // Pas de flèche retour sur les pages principales
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Color(0xFF009688)),
              ),
              const SizedBox(height: 15),
              Text(
                user?.email ?? "Doctor",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text("Dermatologist", style: TextStyle(color: Colors.grey)),

              const SizedBox(height: 40),

              _buildProfileOption(Icons.settings, "Settings", () {}),
              _buildProfileOption(Icons.security, "Privacy & Security", () {}),
              _buildProfileOption(Icons.help_outline, "Help & Support", () {}),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Log Out"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF009688)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}

// --- ECRAN HISTORIQUE GLOBAL (Ajouté pour corriger l'erreur) ---
class GlobalHistoryScreen extends StatelessWidget {
  const GlobalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F6),
      appBar: AppBar(
        title: const Text(
          "Recent Activity",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF009688),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.lock_clock, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "Global Analytics Coming Soon",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              "Please access detailed history via Patient Files.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
