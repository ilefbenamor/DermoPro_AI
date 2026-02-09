import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiLabAnalyseScreen extends StatefulWidget {
  const AiLabAnalyseScreen({super.key});

  @override
  State<AiLabAnalyseScreen> createState() => _AiLabAnalyseScreenState();
}

class _AiLabAnalyseScreenState extends State<AiLabAnalyseScreen> {
  File? _image;
  String _result = "";
  bool _loading = false;

  Future<void> _analyzeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _loading = true;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: dotenv.env['GEMINI_API_KEY']!,
      );

      // PROMPT SCIENTIFIQUE POUR LE LAB
      final prompt = """Perform a TECHNICAL differential diagnosis. 
      1. List top 3 likely pathologies with probabilities (%). 
      2. Analyze dermatoscopic structures (pigment network, regression, etc.).
      3. Cite medical literature reasoning.""";

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', await _image!.readAsBytes()),
        ]),
      ];

      final response = await model.generateContent(content);
      setState(() => _result = response.text ?? "No analysis results.");
    } catch (e) {
      setState(() => _result = "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scientific Scan"),
        backgroundColor: const Color(0xFF009688),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_image != null) Image.file(_image!, height: 250),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _analyzeImage,
              icon: const Icon(Icons.photo_camera),
              label: const Text("UPLOAD FOR RESEARCH SCAN"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            if (_loading) const CircularProgressIndicator(),
            if (_result.isNotEmpty) MarkdownBody(data: _result),
          ],
        ),
      ),
    );
  }
}
