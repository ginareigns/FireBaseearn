
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlotScreen extends StatefulWidget {
  final DateTime selectedDate;

  const TimeSlotScreen({super.key, required this.selectedDate});

  @override
  _TimeSlotScreenState createState() => _TimeSlotScreenState();
}

class _TimeSlotScreenState extends State<TimeSlotScreen> {
  String? _selectedTimeSlot;

  final List<String> _timeSlots = [
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 03:00 PM',
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _saveBooking() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    try {
      await _firestore.collection('bookings').add({
        'date': widget.selectedDate.toIso8601String(),
        'timeSlot': _selectedTimeSlot,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking saved successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Time Slot')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_timeSlots[index]),
                  selected: _timeSlots[index] == _selectedTimeSlot,
                  onTap: () {
                    setState(() {
                      _selectedTimeSlot = _timeSlots[index];
                    });
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _saveBooking,
            child: const Text('Save Booking'),
          ),
        ],
      ),
    );
  }
}
