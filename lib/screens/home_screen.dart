import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'medical_report_analysis_screen.dart';
import 'notification_settings_screen.dart';
import 'symptom_analysis_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SELECT AN OPTION',
          style: TextStyle(
            color: Colors.blueAccent,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.gear,
              color: Colors.blue,
              size: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildOptionButton(
              'Symptom Analysis',
              FontAwesomeIcons.stethoscope,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SymptomAnalysisScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildOptionButton(
              'Medical Report Analysis',
              FontAwesomeIcons.fileMedical,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MedicalReportAnalysisScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildOptionButton('Calenders', FontAwesomeIcons.calendar, () {
              // TODO: Implement calendars
            }),
            const SizedBox(height: 24),
            _buildOptionButton(
              'Medical Records',
              FontAwesomeIcons.hospitalUser,
              () {
                // TODO: Implement medical records
              },
            ),
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
          if (index == 1) {
            // Profile tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          } else if (index == 2) {
            // Notifications tab
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

  Widget _buildOptionButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        icon: FaIcon(icon, color: Colors.white, size: 20),
        label: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
