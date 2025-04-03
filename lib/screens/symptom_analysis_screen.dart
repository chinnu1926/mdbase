import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import '../services/medication_service.dart';

class SymptomAnalysisScreen extends StatefulWidget {
  const SymptomAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<SymptomAnalysisScreen> createState() => _SymptomAnalysisScreenState();
}

class _SymptomAnalysisScreenState extends State<SymptomAnalysisScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  int _questionsAsked = 0;
  static const int _maxQuestions = 10;
  late final GenerativeModel _model;
  String _finalDiagnosis = '';

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-001',
      apiKey: MedicationService.apiKey,
    );
  }

  Future<void> _askFollowUpQuestion(
    String userSymptoms,
    List<String> responses,
  ) async {
    if (_questionsAsked >= _maxQuestions) {
      _generateFinalDiagnosis(responses);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prompt = '''
      User symptoms: $userSymptoms. Previous responses: ${responses.join(', ')}. 
      Ask ONE short and relevant follow-up question. Keep it professional, concise, 
      and without unnecessary annotations or emojis.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final followUp = response.text?.trim() ?? '';

      if (followUp.isEmpty ||
          followUp.toLowerCase().contains('enough information')) {
        _generateFinalDiagnosis(responses);
        return;
      }

      setState(() {
        _messages.add(ChatMessage(text: followUp, isUser: false));
        _questionsAsked++;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _generateFinalDiagnosis(List<String> responses) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Format the conversation history
      final conversationHistory = _messages
          .map((msg) => '${msg.isUser ? "User" : "Assistant"}: ${msg.text}')
          .join('\n');

      final prompt = '''
      Based on this conversation history:
      $conversationHistory

      Provide a structured diagnosis strictly formatted as follows without unnecessary annotations or emojis:

      - Disease:
      - Possible Causes:
      - Remedies:
      - Specialist Recommendation:
      - Risk Level (Consult doctor immediately or stay at home):
      - Special Precautions:
      - Note:
      - Disclaimer (concise and professional).

      IMPORTANT: Return ONLY the diagnosis in the above format, without any additional text or formatting.
      ''';

      print("Generating final diagnosis with prompt: $prompt"); // Debug print

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final diagnosis = response.text?.trim() ?? '';

      print("Received diagnosis: $diagnosis"); // Debug print

      if (diagnosis.isEmpty) {
        throw Exception('No diagnosis generated');
      }

      setState(() {
        _finalDiagnosis = diagnosis;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print("Error in _generateFinalDiagnosis: $e"); // Debug print
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating diagnosis: $e')));
    }
  }

  void _startSymptomAnalysis() {
    if (_symptomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your symptoms')),
      );
      return;
    }

    setState(() {
      _messages.clear();
      _questionsAsked = 0;
      _finalDiagnosis = '';
      _messages.add(ChatMessage(text: _symptomController.text, isUser: true));
    });

    _askFollowUpQuestion(_symptomController.text, []);
    _symptomController.clear();
    _scrollToBottom();
  }

  void _submitResponse() {
    if (_responseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your response')),
      );
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: _responseController.text, isUser: true));
    });

    final responses =
        _messages
            .where((msg) => !msg.isUser)
            .map(
              (msg) =>
                  '${msg.text} -> ${_messages[_messages.indexOf(msg) + 1].text}',
            )
            .toList();

    _askFollowUpQuestion(_messages.first.text, responses);
    _responseController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Analysis'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  _messages.length + (_finalDiagnosis.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _finalDiagnosis.isNotEmpty) {
                  return Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Final Diagnosis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_finalDiagnosis),
                        ],
                      ),
                    ),
                  );
                }

                final message = _messages[index];
                return Align(
                  alignment:
                      message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          message.isUser
                              ? Colors.blueAccent
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _symptomController,
                    decoration: const InputDecoration(
                      hintText:
                          'Enter your symptoms (e.g., fever and cough for 3 days)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startSymptomAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Start Analysis'),
                  ),
                ],
              ),
            )
          else if (_finalDiagnosis.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _responseController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your response',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _submitResponse,
                    icon: const Icon(Icons.send),
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
