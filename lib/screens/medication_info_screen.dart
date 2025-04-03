import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/medication_service.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'notification_settings_screen.dart';
import 'dart:convert';

class MedicationInfoScreen extends StatefulWidget {
  const MedicationInfoScreen({Key? key}) : super(key: key);

  @override
  State<MedicationInfoScreen> createState() => _MedicationInfoScreenState();
}

class _MedicationInfoScreenState extends State<MedicationInfoScreen> {
  final TextEditingController _searchController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Map<String, dynamic>? _medicationInfo;
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-001',
      apiKey: MedicationService.apiKey,
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _searchMedication() async {
    if (_searchController.text.isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a medicine name or upload an image'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _medicationInfo = null;
    });

    try {
      String medicineName = _searchController.text;

      if (_image != null) {
        // TODO: Implement image recognition to get medicine name
        // For now, we'll use the text input if available
        if (medicineName.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter the medicine name')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final prompt = '''
      Provide information about '$medicineName' in a clear format. Do not include any asterisks or markdown formatting.

      Format the response as follows:

      [Medicine Name] Information

      1. Usage:
      • Primary use: [Brief description]
      • How it works: [Mechanism of action]
      • When to take it: [Usage instructions]

      2. Side Effects:
      • Common side effects: [List common effects]
      • Serious side effects: [List serious effects]
      • When to seek medical help: [Emergency situations]

      3. Dosage:
      • Standard dosage: [Regular dose]
      • Maximum dosage: [Maximum limits]
      • Special instructions: [Important notes]

      4. Warnings:
      • Important precautions: [Key warnings]
      • Drug interactions: [Interactions to avoid]
      • Who should avoid it: [Contraindications]

      Keep the information concise but comprehensive. Use bullet points (•) for clarity.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        setState(() {
          _medicationInfo = {
            'medicine_name': medicineName,
            'content': response.text!,
            'date_added': DateTime.now(),
          };
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching medication: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMedication(bool isCurrentMedication) async {
    if (_medicationInfo == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save medication')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .add({
            ..._medicationInfo!,
            'is_current_medication': isCurrentMedication,
            'date_added': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving medication: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Information'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Enter Medicine Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            if (_image != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _searchMedication,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_medicationInfo != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormattedText(_medicationInfo!['content']),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Do you take this medication?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _saveMedication(true),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Yes, I Take This'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _saveMedication(false),
                            icon: const Icon(Icons.not_interested),
                            label: const Text('No, I Don\'t'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blueAccent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house, size: 20),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.user, size: 20),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.bell, size: 20),
            label: 'Notifications',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFormattedText(String text) {
    final List<String> lines = text.split('\n');
    List<TextSpan> spans = [];

    for (String line in lines) {
      if (line.trim().isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Format section headers (1. Usage:, 2. Side Effects:, etc.)
      if (line.trim().startsWith(RegExp(r'\d\.'))) {
        spans.add(
          TextSpan(
            text: '\n$line\n',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
              height: 2.0,
            ),
          ),
        );
      }
      // Format subsection headers (Primary use:, How it works:, etc.)
      else if (line.trim().startsWith('•')) {
        final parts = line.split(':');
        if (parts.length > 1) {
          spans.add(
            TextSpan(
              text: '${parts[0]}:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          );
          spans.add(
            TextSpan(
              text: '${parts.sublist(1).join(':')}\n',
              style: const TextStyle(color: Colors.black87),
            ),
          );
        } else {
          spans.add(TextSpan(text: '$line\n'));
        }
      }
      // Format medicine name header
      else if (line.contains('Information')) {
        spans.add(
          TextSpan(
            text: line,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
              height: 2.0,
            ),
          ),
        );
      }
      // Normal text
      else {
        spans.add(TextSpan(text: '$line\n'));
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
        ),
        children: spans,
      ),
    );
  }
}
