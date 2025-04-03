import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() {
    print('Creating CalendarScreen state');
    return _CalendarScreenState();
  }
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isMedicationReminder = true;
  final _medicationNameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('Initializing CalendarScreen');
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _selectedDate,
      firstDate: _selectedDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addReminder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }

        final reminder = {
          'name': _medicationNameController.text,
          'notes': _notesController.text,
          'date': Timestamp.fromDate(_selectedDate),
          'time': '${_selectedTime.hour}:${_selectedTime.minute}',
          'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
          'isMedication': _isMedicationReminder,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('reminders').add(reminder);

        _medicationNameController.clear();
        _notesController.clear();
        _endDate = null;
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding reminder: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteReminder(String reminderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(reminderId)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting reminder: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building CalendarScreen');
    final user = FirebaseAuth.instance.currentUser;
    print('Current user: ${user?.uid}');
    if (user == null) {
      print('No user logged in');
      return const Scaffold(
        body: Center(child: Text('Please log in to view reminders')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Medication Reminder'),
                          value: true,
                          groupValue: _isMedicationReminder,
                          onChanged: (value) {
                            setState(() {
                              _isMedicationReminder = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Doctor Appointment'),
                          value: false,
                          groupValue: _isMedicationReminder,
                          onChanged: (value) {
                            setState(() {
                              _isMedicationReminder = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _medicationNameController,
                    decoration: InputDecoration(
                      labelText:
                          _isMedicationReminder
                              ? 'Medication Name'
                              : 'Doctor Name',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Date'),
                          subtitle: Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                          ),
                          onTap: () => _selectDate(context),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Time'),
                          subtitle: Text(_selectedTime.format(context)),
                          onTap: () => _selectTime(context),
                        ),
                      ),
                    ],
                  ),
                  if (_isMedicationReminder) ...[
                    ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(
                        _endDate != null
                            ? DateFormat('MMM dd, yyyy').format(_endDate!)
                            : 'Not set',
                      ),
                      onTap: () => _selectEndDate(context),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Add Reminder'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('reminders')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('date', descending: false)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Error loading reminders'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reminders = snapshot.data?.docs ?? [];

                if (reminders.isEmpty) {
                  return const Center(child: Text('No reminders yet'));
                }

                return ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder =
                        reminders[index].data() as Map<String, dynamic>;
                    final reminderId = reminders[index].id;
                    final date = (reminder['date'] as Timestamp).toDate();
                    final time = reminder['time'] as String;
                    final timeParts = time.split(':');
                    final reminderTime = TimeOfDay(
                      hour: int.parse(timeParts[0]),
                      minute: int.parse(timeParts[1]),
                    );

                    return Slidable(
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => _deleteReminder(reminderId),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(
                          reminder['isMedication']
                              ? FontAwesomeIcons.pills
                              : FontAwesomeIcons.userDoctor,
                          color: Colors.blueAccent,
                        ),
                        title: Text(reminder['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reminder['notes']),
                            Text(
                              '${DateFormat('MMM dd, yyyy').format(date)} at ${reminderTime.format(context)}',
                            ),
                            if (reminder['isMedication'] &&
                                reminder['endDate'] != null)
                              Text(
                                'Ends: ${DateFormat('MMM dd, yyyy').format((reminder['endDate'] as Timestamp).toDate())}',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
