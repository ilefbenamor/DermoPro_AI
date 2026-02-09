import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart'; // Vérifie que le chemin est correct
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animController;

  // Palette DermoPro AI
  final Color colPrimary = const Color(0xFF009688); // Teal médical
  final Color colBg = const Color(0xFFFBFDFD); // Blanc clinique
  final Color colTextDeep = const Color(0xFF2D3231); // Anthracite

  @override
  void initState() {
    super.initState();
    // Animation du scanner HUD (4 secondes pour un tour complet)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIQUE FIREBASE : CONNEXION ---
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Please provide both ID and Security Key.", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Authentification Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. NAVIGATION CRUCIALE : On vide la pile et on va à l'accueil
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Access Denied: Authentication failed.";
      if (e.code == 'user-not-found')
        errorMsg = "No practitioner found with this ID.";
      if (e.code == 'wrong-password') errorMsg = "Incorrect Security Key.";

      _showSnackBar(errorMsg, Colors.red);
    } catch (e) {
      _showSnackBar("An unexpected error occurred.", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIQUE FIREBASE : MOT DE PASSE OUBLIÉ ---
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar("Please enter your Professional ID first.", Colors.orange);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      _showSnackBar(
        "Recovery protocol initiated. Check your email.",
        Colors.green,
      );
    } catch (e) {
      _showSnackBar("Failed to send recovery email.", Colors.red);
    }
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colBg,
      body: Stack(
        children: [
          // FOND ANIMÉ : HUD SCANNER (L'effet laser créatif)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: HUDScannerPainter(_animController.value, colPrimary),
                );
              },
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // TITRE PRO
                    Text(
                      "DermoPro AI",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: colTextDeep,
                        letterSpacing: -1.5,
                      ),
                    ),
                    Row(
                      children: [
                        Container(height: 2, width: 40, color: colPrimary),
                        const SizedBox(width: 10),
                        Text(
                          "PHYSICIAN PORTAL",
                          style: TextStyle(
                            fontSize: 12,
                            color: colPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4.0,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 80),

                    // CHAMPS DE SAISIE
                    _buildInput(
                      controller: _emailController,
                      label: "PROFESSIONAL IDENTIFIER",
                      icon: Icons.person_search_rounded,
                    ),
                    const SizedBox(height: 30),
                    _buildInput(
                      controller: _passwordController,
                      label: "SECURITY ENCRYPTION KEY",
                      icon: Icons.vpn_key_rounded,
                      isPass: true,
                    ),

                    // MOT DE PASSE OUBLIÉ
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: Text(
                          "Forgot Key?",
                          style: TextStyle(
                            color: colPrimary.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // BOUTON DE CONNEXION
                    SizedBox(
                      width: double.infinity,
                      height: 65,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ), // Look plus logiciel pro
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "INITIALIZE SESSION",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // LIEN VERS SIGNUP
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const SignupScreen(),
                          ),
                        ),
                        child: RichText(
                          text: TextSpan(
                            text: "New Practitioner? ",
                            style: TextStyle(
                              color: colTextDeep.withOpacity(0.5),
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: "Request Access",
                                style: TextStyle(
                                  color: colPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPass = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: colPrimary.withOpacity(0.6),
            letterSpacing: 1.5,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPass,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: colPrimary, size: 20),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colPrimary.withOpacity(0.1)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colPrimary, width: 2),
            ),
            hintText: isPass ? "••••••••" : "doctor@clinic.com",
            hintStyle: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

// --- PAINTER DU SCANNER HUD (Le design créatif) ---
class HUDScannerPainter extends CustomPainter {
  final double progress;
  final Color color;
  HUDScannerPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final margin = 40.0;
    final rect = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );

    // On dessine le cadre de zone
    canvas.drawRect(rect, paint);

    final headPaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    double perimeter = (rect.width + rect.height) * 2;
    double currentDist = progress * perimeter;

    Offset headPos;
    if (currentDist < rect.width) {
      headPos = Offset(rect.left + currentDist, rect.top);
    } else if (currentDist < rect.width + rect.height) {
      headPos = Offset(rect.right, rect.top + (currentDist - rect.width));
    } else if (currentDist < rect.width * 2 + rect.height) {
      headPos = Offset(
        rect.right - (currentDist - (rect.width + rect.height)),
        rect.bottom,
      );
    } else {
      headPos = Offset(
        rect.left,
        rect.bottom - (currentDist - (rect.width * 2 + rect.height)),
      );
    }

    // Le point laser brillant
    canvas.drawCircle(headPos, 4, headPaint);
    canvas.drawCircle(headPos, 2, Paint()..color = Colors.white);

    // Les lignes de visée laser
    canvas.drawLine(
      Offset(headPos.dx, 0),
      Offset(headPos.dx, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, headPos.dy),
      Offset(size.width, headPos.dy),
      paint,
    );

    // Les crochets de focus aux quatre coins
    _drawCorner(
      canvas,
      rect.topLeft,
      20,
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
    _drawCorner(
      canvas,
      rect.topRight,
      20,
      Paint()
        ..color = color
        ..strokeWidth = 2,
      rotate: 1,
    );
    _drawCorner(
      canvas,
      rect.bottomLeft,
      20,
      Paint()
        ..color = color
        ..strokeWidth = 2,
      rotate: 3,
    );
    _drawCorner(
      canvas,
      rect.bottomRight,
      20,
      Paint()
        ..color = color
        ..strokeWidth = 2,
      rotate: 2,
    );
  }

  void _drawCorner(
    Canvas canvas,
    Offset center,
    double len,
    Paint paint, {
    int rotate = 0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotate * math.pi / 2);
    canvas.drawLine(Offset.zero, Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, len), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
