import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool generalNotification = true;
  bool sound = true;
  bool soundCall = true;
  bool vibrate = false;

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
                'Notification Setting',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            _buildNotificationOption(
              'General Notification',
              generalNotification,
              (value) => setState(() => generalNotification = value),
            ),
            _buildNotificationOption(
              'Sound',
              sound,
              (value) => setState(() => sound = value),
            ),
            _buildNotificationOption(
              'Sound Call',
              soundCall,
              (value) => setState(() => soundCall = value),
            ),
            _buildNotificationOption(
              'Vibrate',
              vibrate,
              (value) => setState(() => vibrate = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.blue),
        ],
      ),
    );
  }
}
