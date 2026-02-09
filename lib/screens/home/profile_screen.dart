import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupération de l'utilisateur connecté
    final user = FirebaseAuth.instance.currentUser;

    // Ta palette de couleurs
    const Color colBg = Color(0xFFF2F7F6);
    const Color colPrimary = Color(0xFF00A896);
    const Color colText = Color(0xFF1A3D37);

    return Scaffold(
      backgroundColor: colBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // --- HEADER AVATAR ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundColor: Color(0xFFE0F2F1),
                        child: Icon(Icons.person, size: 60, color: colPrimary),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: colPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- INFOS UTILISATEUR ---
              Text(
                user?.displayName ?? "Utilisateur LumiDerm",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                user?.email ?? "email@exemple.com",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              // --- LISTE DES OPTIONS STYLE "CLEAN UI" ---
              _buildOption(Icons.notifications_none_rounded, "Notifications"),
              _buildOption(
                Icons.security_rounded,
                "Sécurité & Confidentialité",
              ),
              _buildOption(Icons.help_outline_rounded, "Centre d'aide"),
              _buildOption(Icons.info_outline_rounded, "À propos de LumiDerm"),

              const SizedBox(height: 30),

              // --- BOUTON DÉCONNEXION ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    "SE DÉCONNECTER",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Espace pour ne pas être caché par la barre de navigation flottante
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour créer les lignes d'options élégantes
  Widget _buildOption(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00A896), size: 24),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF1A3D37),
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
