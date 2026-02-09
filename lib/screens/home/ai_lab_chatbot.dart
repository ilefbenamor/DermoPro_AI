import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiLabChatbotScreen extends StatefulWidget {
  const AiLabChatbotScreen({super.key});

  @override
  State<AiLabChatbotScreen> createState() => _AiLabChatbotScreenState();
}

class _AiLabChatbotScreenState extends State<AiLabChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    String userMsg = _controller.text;
    setState(() {
      _messages.add({"role": "user", "content": userMsg});
      _isTyping = true;
      _controller.clear();
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: dotenv.env['GEMINI_API_KEY']!,
        systemInstruction: Content.system(
          "You are an expert Dermatologist Consultant. Answer scientific questions accurately and cite protocols.",
        ),
      );

      final response = await model.generateContent([Content.text(userMsg)]);
      setState(() {
        _messages.add({
          "role": "ai",
          "content": response.text ?? "No response.",
        });
      });
    } catch (e) {
      setState(() => _messages.add({"role": "ai", "content": "Error: $e"}));
    } finally {
      setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expert Consultant Chat"),
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]["role"] == "user";
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF009688)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: MarkdownBody(
                      data: _messages[index]["content"]!,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask Gemini about dermatology...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF009688)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
