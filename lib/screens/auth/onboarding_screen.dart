import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Animation de flottaison
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fonction de navigation
  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    const Color colStart = Color(0xFF009688); // Teal
    const Color colEnd = Color(0xFF80CBC4); // Light Teal

    return Scaffold(
      body: GestureDetector(
        // Utilisation de DragUpdate pour une détection immédiate et sensible
        onHorizontalDragUpdate: (details) {
          // Si le mouvement du doigt va vers la gauche (delta négatif)
          if (details.delta.dx < -6) {
            _goToLogin();
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colStart, colEnd],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // LOGO ANIMÉ
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 200,
                        // Si l'image ne charge pas, on met une icône par défaut pour éviter le crash
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.medical_services,
                              size: 100,
                              color: Colors.white,
                            ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              const Text(
                "DermoPro AI",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),

              const Text(
                "Your Professional Dermatology Assistant",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(flex: 2),

              // INDICATEUR VISUEL
              // On entoure aussi d'un InkWell au cas où le juge préfère cliquer
              InkWell(
                onTap: _goToLogin,
                child: Column(
                  children: [
                    const Icon(
                      Icons.keyboard_double_arrow_left,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "SWIPE LEFT TO START",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
