import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isCertify = false; // Mandatory Checkbox

  // Palette Pro
  final Color colBg = const Color(0xFFF2F7F6);
  final Color colPrimary = const Color(0xFF009688);
  final Color colText = const Color(0xFF1A3D37);

  Future<void> _signUp() async {
    // 1. Strict Validations
    if (!_isCertify) {
      _showError("You must certify that you are a healthcare professional.");
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match.");
      return;
    }
    if (_nameController.text.isEmpty ||
        _licenseController.text.isEmpty ||
        _specialtyController.text.isEmpty) {
      _showError("All professional fields are required.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Create Auth User
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 3. Save to Firestore (Doctors Collection)
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(userCredential.user!.uid)
          .set({
            'full_name': _nameController.text.trim(),
            'medical_license_id': _licenseController.text.trim(),
            'specialty': _specialtyController.text.trim(),
            'email': _emailController.text.trim(),
            'created_at': FieldValue.serverTimestamp(),
            'is_verified': false,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created. Welcome, Doctor.")),
        );
        Navigator.pop(context); // Go back to login
      }
    } catch (e) {
      _showError("Registration Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: colText),
        title: Text(
          "Practitioner Registration",
          style: TextStyle(
            color: colText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Professional Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                "This data is required to validate your medical practice.",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 25),

              // IDENTITY SECTION
              _buildLabel("Identity"),
              _buildInput(
                _nameController,
                "Dr. Full Name",
                Icons.person_outline,
              ),
              const SizedBox(height: 15),

              _buildLabel("Medical Credentials"),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      _licenseController,
                      "License ID / NPI",
                      Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInput(
                      _specialtyController,
                      "Specialty (e.g. Derm)",
                      Icons.local_hospital_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ACCOUNT SECTION
              _buildLabel("Login Credentials"),
              _buildInput(
                _emailController,
                "Professional Email",
                Icons.email_outlined,
              ),
              const SizedBox(height: 15),
              _buildInput(
                _passwordController,
                "Password",
                Icons.lock_outline,
                isPass: true,
              ),
              const SizedBox(height: 15),
              _buildInput(
                _confirmPasswordController,
                "Confirm Password",
                Icons.lock_reset,
                isPass: true,
              ),

              const SizedBox(height: 25),

              // LEGAL CHECKBOX
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isCertify,
                      activeColor: colPrimary,
                      onChanged: (v) => setState(() => _isCertify = v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        "I certify on my honor that I am a licensed healthcare professional.",
                        style: TextStyle(
                          fontSize: 12,
                          color: colText,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "COMPLETE REGISTRATION",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 5),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPass = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 15,
          ),
        ),
      ),
    );
  }
}
