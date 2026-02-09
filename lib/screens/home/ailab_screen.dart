import 'package:flutter/material.dart';
import 'ai_lab_analyse.dart';
import 'ai_lab_chatbot.dart';

class AiLabMainScreen extends StatelessWidget {
  const AiLabMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const colPrimary = Color(0xFF009688);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        title: const Text(
          "DermoPro AI Lab",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Advanced Research Tools",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3D37),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Powered by Gemini 3 Multimodal Reasoning",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // CARTE 1 : ANALYSE SCIENTIFIQUE
            _buildLabCard(
              context,
              title: "Differential Diagnosis Scan",
              desc:
                  "Upload a lesion for a detailed technical analysis with probability scoring.",
              icon: Icons.biotech,
              color: colPrimary,
              destination: const AiLabAnalyseScreen(),
            ),

            const SizedBox(height: 20),

            // CARTE 2 : CHATBOT EXPERT
            _buildLabCard(
              context,
              title: "Expert Clinical Consultant",
              desc:
                  "Ask Gemini about protocols, rare diseases, or specific treatment guidelines.",
              icon: Icons.psychology_outlined,
              color: Colors.deepPurple.shade400,
              destination: const AiLabChatbotScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
