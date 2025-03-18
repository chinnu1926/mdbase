import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_settings_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  bool isLoading = true;
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  String? selectedBloodGroup;
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Reset all fields first
      nameController.text = '';
      ageController.text = '';
      heightController.text = '';
      weightController.text = '';
      selectedBloodGroup = null;
      selectedGender = null;

      // Set the name from Google account immediately
      final displayName = user.displayName ?? user.email?.split('@')[0] ?? '';
      nameController.text = displayName;

      // Get profile data from Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          // Only update fields if they exist in Firestore
          if (data['name'] != null) {
            nameController.text = data['name'];
          }
          if (data['age'] != null) {
            ageController.text = data['age'].toString();
          }
          if (data['height'] != null) {
            heightController.text = data['height'].toString();
          }
          if (data['weight'] != null) {
            weightController.text = data['weight'].toString();
          }
          if (data['bloodGroup'] != null) {
            selectedBloodGroup = data['bloodGroup'];
          }
          if (data['gender'] != null) {
            selectedGender = data['gender'];
          }
          setState(() {
            isLoading = false;
          });
        }
      } else {
        // Create new profile with Google account data
        final initialData = {
          'name': displayName,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(initialData);

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool get isValidForm {
    return nameController.text.isNotEmpty &&
        ageController.text.isNotEmpty &&
        heightController.text.isNotEmpty &&
        weightController.text.isNotEmpty &&
        selectedBloodGroup != null &&
        selectedGender != null;
  }

  Future<void> _handleSave() async {
    if (!isValidForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all the fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // First update the UI to show we're not editing anymore
        setState(() {
          isEditing = false;
        });

        // Then save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': nameController.text,
          'age': int.tryParse(ageController.text) ?? 0,
          'height': double.tryParse(heightController.text) ?? 0.0,
          'weight': double.tryParse(weightController.text) ?? 0.0,
          'bloodGroup': selectedBloodGroup,
          'gender': selectedGender,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.blue,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Center(
              child: Text(
                'Profile',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.save : Icons.edit,
              color: Colors.blue,
              size: 24,
            ),
            onPressed: () {
              if (isEditing) {
                _handleSave();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (!isEditing)
                            Text(
                              nameController.text.isEmpty
                                  ? 'Not set'
                                  : nameController.text,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            )
                          else
                            TextField(
                              controller: nameController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            'Age',
                            TextInputType.number,
                            ageController,
                            isEditing,
                            'Enter your age',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            'Height (m)',
                            TextInputType.number,
                            heightController,
                            isEditing,
                            'Enter your height',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            'Weight (kg)',
                            TextInputType.number,
                            weightController,
                            isEditing,
                            'Enter your weight',
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            'Blood Group',
                            selectedBloodGroup,
                            ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
                            (value) {
                              if (isEditing) {
                                setState(() {
                                  selectedBloodGroup = value;
                                });
                              }
                            },
                            isEditing,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            'Gender',
                            selectedGender,
                            ['Male', 'Female', 'Other'],
                            (value) {
                              if (isEditing) {
                                setState(() {
                                  selectedGender = value;
                                });
                              }
                            },
                            isEditing,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blueAccent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        currentIndex: 1,
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

  Widget _buildTextField(
    String label,
    TextInputType keyboardType,
    TextEditingController controller,
    bool isEditing,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (!isEditing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              controller.text.isEmpty ? 'Not set' : controller.text,
              style: TextStyle(
                fontSize: 16,
                color: controller.text.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          )
        else
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.blue.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
    bool isEditing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (!isEditing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value ?? 'Not set',
              style: TextStyle(
                fontSize: 16,
                color: value == null ? Colors.grey : Colors.black,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items:
                    items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                onChanged: onChanged,
                hint: Text('Select $label'),
              ),
            ),
          ),
      ],
    );
  }
}
