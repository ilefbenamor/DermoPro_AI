import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Imports PDF et Impression
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DoctorHomeScreen extends StatefulWidget {
  final String patientName;
  final String patientId;

  const DoctorHomeScreen({
    super.key,
    required this.patientName,
    required this.patientId,
  });

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  // --- VARIABLES D'ÉTAT ---
  File? _currentImage;
  File? _baselineImage;
  bool _isComparisonMode = false;
  String _result = "";
  bool _isLoading = false;

  final TextEditingController _notesController = TextEditingController();
  final _picker = ImagePicker();

  bool _isListening = false;
  bool _isProcessingVoice = false;

  static const String modelName = 'gemini-3-flash-preview';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // --- FONCTION EXPORT PDF CORRIGÉE (TEXTE GARANTI) ---
  Future<void> _generatePdfReport() async {
    if (_result.isEmpty) {
      _showError("No analysis result to export.");
      return;
    }

    try {
      final pdf = pw.Document();
      final font = pw.Font.helvetica();

      // Nettoyage du texte Gemini (suppression du gras/titres Markdown pour le PDF)
      String cleanResult = _result
          .replaceAll('**', '')
          .replaceAll('*', '')
          .replaceAll('#', '')
          .replaceAll('•', '-')
          .trim();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          build: (pw.Context context) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "DermoPro AI - CLINICAL REPORT",
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal,
                    ),
                  ),
                  pw.Text(
                    DateTime.now().toString().substring(0, 16),
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // Infos Patient
              pw.Text(
                "PATIENT DETAILS",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                "Name: ${widget.patientName}",
                style: pw.TextStyle(font: font, fontSize: 11),
              ),
              pw.Text(
                "ID: ${widget.patientId}",
                style: pw.TextStyle(font: font, fontSize: 11),
              ),

              pw.SizedBox(height: 20),

              // Notes du médecin
              pw.Text(
                "PHYSICIAN NOTES",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                _notesController.text.isEmpty
                    ? "No clinical notes."
                    : _notesController.text,
                style: pw.TextStyle(font: font, fontSize: 11),
              ),

              pw.SizedBox(height: 25),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 10),

              // RÉSULTAT DE L'IA (Le coeur du rapport)
              pw.Text(
                "AI DIAGNOSTIC INSIGHTS (GEMINI 3)",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Text(
                cleanResult,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),

              pw.SizedBox(height: 40),
              pw.Divider(thickness: 0.5),
              pw.Text(
                "Notice: This is an AI-generated clinical support document. It does not replace a professional medical diagnosis.",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ];
          },
        ),
      );

      // Lancement de l'interface d'impression/sauvegarde
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Report_${widget.patientName}',
      );
    } catch (e) {
      _showError("Failed to build PDF result: $e");
    }
  }

  // --- LOGIQUE VOCALE (SIMULÉE POUR STABILITÉ DÉMO) ---
  Future<void> _toggleRecording() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      await Future.delayed(const Duration(seconds: 4)); // Temps pour "parler"
      setState(() {
        _isListening = false;
        _isProcessingVoice = true;
      });
      _simulateGeminiTranscription();
    }
  }

  Future<void> _simulateGeminiTranscription() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      final model = GenerativeModel(model: modelName, apiKey: apiKey!);
      const prompt = """
        CONTEXT: Medical Scribe. TASK: Professional clinical observation. 
        INPUT: '19-year-old male. Red itchy spots on back, 2 weeks, no pain.'
      """;
      final response = await model.generateContent([Content.text(prompt)]);
      if (mounted && response.text != null) {
        setState(() => _notesController.text = response.text!.trim());
      }
    } catch (e) {
      _showError("Transcription error");
    } finally {
      if (mounted) setState(() => _isProcessingVoice = false);
    }
  }

  // --- ANALYSE IA (PHOTO / COMPARAISON) ---
  Future<void> _analyzeCase() async {
    if (_currentImage == null) return;
    if (_isComparisonMode && _baselineImage == null) {
      _showError("Select a Reference Image.");
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey!,
        systemInstruction: Content.system(
          "You are DermoPro AI. Use professional terminology and ABCDE criteria.",
        ),
      );

      List<Part> parts = [];
      String promptText =
          "Patient: ${widget.patientName}. Context: ${_notesController.text}. ";

      if (_isComparisonMode) {
        promptText +=
            "Compare Img 1 (Baseline) and Img 2 (Current). Detect evolution.";
        parts.add(TextPart(promptText));
        parts.add(DataPart('image/jpeg', await _baselineImage!.readAsBytes()));
        parts.add(DataPart('image/jpeg', await _currentImage!.readAsBytes()));
      } else {
        promptText += "Scan this lesion. Provide a clinical SOAP report.";
        parts.add(TextPart(promptText));
        parts.add(DataPart('image/jpeg', await _currentImage!.readAsBytes()));
      }

      final response = await model.generateContent([Content.multi(parts)]);
      if (mounted) {
        setState(() => _result = response.text ?? "No output from AI.");
        await _saveToPatientRecord(_result);
      }
    } catch (e) {
      _showError("AI Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToPatientRecord(String analysis) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .collection('patients')
          .doc(widget.patientId)
          .collection('analyses')
          .add({
            'created_at': FieldValue.serverTimestamp(),
            'analysis_result': analysis,
            'type': _isComparisonMode ? 'comparative' : 'standard',
          });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
  }

  // --- INTERFACE (UI) ---
  @override
  Widget build(BuildContext context) {
    const colPrimary = Color(0xFF009688);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F6),
      appBar: AppBar(
        title: const Text(
          "DermoPro AI Assessment",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: colPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle Evolution
            SwitchListTile(
              title: const Text(
                "Evolution Mode",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: _isComparisonMode,
              activeColor: colPrimary,
              onChanged: (val) => setState(() {
                _isComparisonMode = val;
                if (!val) _baselineImage = null;
              }),
            ),
            const SizedBox(height: 15),

            // Cartes Image
            Row(
              children: [
                if (_isComparisonMode)
                  Expanded(
                    child: _buildImageCard(
                      "Baseline",
                      _baselineImage,
                      () => _showImageSourceDialog(isBaseline: true),
                      Colors.orange,
                    ),
                  ),
                if (_isComparisonMode) const SizedBox(width: 10),
                Expanded(
                  child: _buildImageCard(
                    _isComparisonMode ? "Today" : "Lesion Scan",
                    _currentImage,
                    () => _showImageSourceDialog(isBaseline: false),
                    colPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Clinical Notes",
                hintText: _isListening
                    ? "Listening..."
                    : "Tap mic to dictate...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.note_alt),
                suffixIcon: _isProcessingVoice
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(
                          _isListening ? Icons.stop_circle : Icons.mic,
                          color: _isListening ? Colors.red : colPrimary,
                        ),
                        onPressed: _toggleRecording,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Bouton Analyse
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: (_currentImage != null && !_isLoading)
                    ? _analyzeCase
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "GENERATE AI ASSESSMENT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            // Résultats et PDF
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "AI Clinical Findings",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _generatePdfReport,
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: MarkdownBody(data: _result),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _generatePdfReport,
                icon: const Icon(Icons.download),
                label: const Text("EXPORT AS PDF REPORT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                ),
              ),
            ],
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  void _showImageSourceDialog({required bool isBaseline}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isBaseline: isBaseline);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isBaseline: isBaseline);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource s, {required bool isBaseline}) async {
    final file = await _picker.pickImage(source: s, imageQuality: 85);
    if (file != null) {
      setState(() {
        if (isBaseline)
          _baselineImage = File(file.path);
        else {
          _currentImage = File(file.path);
          _result = "";
        }
      });
    }
  }

  Widget _buildImageCard(
    String title,
    File? file,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: file == null ? Colors.grey.shade300 : color,
            width: 2,
          ),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(file, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: color, size: 30),
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
