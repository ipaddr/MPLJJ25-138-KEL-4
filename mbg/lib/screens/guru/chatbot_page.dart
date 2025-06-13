import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
class ChatMessage {
  final String text;
  final bool isUserMessage;

  ChatMessage({required this.text, required this.isUserMessage});
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final String _apiKey = "AIzaSyBx3AA2QHs0Pv4QP_-K9rZl9Yjzck0ci6k";
  
  GenerativeModel? _model;
  ChatSession? _chat;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
    _chat = _model!.startChat();
    _addMessage(ChatMessage(text: "Halo! Saya adalah Chatbot Gizi. Ada yang bisa saya bantu terkait nutrisi atau makanan?", isUserMessage: false));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
  }
  Future<void> _sendMessage() async {
    final userMessageText = _messageController.text.trim();
    _messageController.clear();

    if (userMessageText.isEmpty) return;

    _addMessage(ChatMessage(text: userMessageText, isUserMessage: true));
    _addMessage(ChatMessage(text: "Mengetik...", isUserMessage: false));
    final currentContext = context;

    try {
      if (_chat == null) {
        throw Exception("Sesi chat Gemini tidak terinisialisasi.");
      }
      final response = await _chat!.sendMessage(Content.text(userMessageText));
      if (!currentContext.mounted) return;
      setState(() {
        _messages.removeLast();
      });
      _addMessage(ChatMessage(text: response.text ?? "Maaf, saya tidak dapat merespons.", isUserMessage: false));

    } catch (e) {
      if (!currentContext.mounted) return;
      setState(() {
        _messages.removeLast();
      });
      _addMessage(ChatMessage(text: "Error: Gagal menghubungi AI. ${e.toString()}", isUserMessage: false));
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text("Error Chatbot: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chatbot Gizi AI"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: message.isUserMessage ? Colors.blue.shade100 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(color: message.isUserMessage ? Colors.blue.shade900 : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration.collapsed(
                        hintText: "Ketik pesan Anda...",
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}