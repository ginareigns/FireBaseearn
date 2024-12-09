import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BookingCalendar(),
    );
  }
}

class BookingCalendar extends StatefulWidget {
  @override
  _BookingCalendarState createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  List<DateTime> selectedDates = [];
  Map<DateTime, List<String>> timeSlots = {};
  List<DateTime> submittedDates = [];

  void saveToFirebase() async {
    if (selectedDates.isNotEmpty) {
      for (var date in selectedDates) {
        await FirebaseFirestore.instance.collection('bookings').add({
          'date': date.toIso8601String(),
          'timeSlots': timeSlots[date] ?? [],
        });
      }

      setState(() {
        submittedDates.addAll(selectedDates);
        selectedDates.clear();
        timeSlots.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking saved successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No dates selected!")),
      );
    }
  }

  void showTimeSlotDialog(DateTime date) async {
    final initialSlots = timeSlots[date] ?? [];
    final selectedSlots = await showDialog<List<String>>(
      context: context,
      builder: (context) => SelectTimeDialog(
        availableTimeSlots: [
          '9:00 AM - 10:00 AM',
          '10:00 AM - 11:00 AM',
          '2:00 PM - 3:00 PM',
          '3:00 PM - 4:00 PM',
        ],
        initialSlots: initialSlots,
      ),
    );

    if (selectedSlots != null) {
      setState(() {
        timeSlots[date] = selectedSlots;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Calendar"),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: DateTime.now(),
            selectedDayPredicate: (day) => selectedDates.contains(day),
            onDaySelected: (selectedDay, _) {
              setState(() {
                if (selectedDates.contains(selectedDay)) {
                  selectedDates.remove(selectedDay);
                  timeSlots.remove(selectedDay);
                } else {
                  selectedDates.add(selectedDay);
                }
              });
            },
            calendarStyle: const CalendarStyle(
              isTodayHighlighted: true,
              selectedDecoration:
                  BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (submittedDates.contains(day)) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: selectedDates.length,
              itemBuilder: (context, index) {
                final date = selectedDates[index];
                return ListTile(
                  title: Text(
                    "${date.year}-${date.month}-${date.day}",
                  ),
                  subtitle: Text(
                    timeSlots[date]?.join(", ") ?? "No time slots selected",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showTimeSlotDialog(date),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: saveToFirebase,
            child: const Text("Save Booking"),
          ),
        ],
      ),
    );
  }
}

class SelectTimeDialog extends StatefulWidget {
  final List<String> availableTimeSlots;
  final List<String> initialSlots;

  const SelectTimeDialog({
    Key? key,
    required this.availableTimeSlots,
    this.initialSlots = const [],
  }) : super(key: key);

  @override
  _SelectTimeDialogState createState() => _SelectTimeDialogState();
}

class _SelectTimeDialogState extends State<SelectTimeDialog> {
  late List<String> selectedSlots;
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedSlots = List.from(widget.initialSlots);
  }

  void addCustomSlot() {
    String startTime = startTimeController.text.trim();
    String endTime = endTimeController.text.trim();
    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      String customSlot = "$startTime - $endTime";
      if (!selectedSlots.contains(customSlot)) {
        setState(() {
          selectedSlots.add(customSlot);
        });
        startTimeController.clear();
        endTimeController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This time slot already exists.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide both start and end times.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Time Slots"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            ...widget.availableTimeSlots.map((slot) {
              return CheckboxListTile(
                title: Text(slot),
                value: selectedSlots.contains(slot),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      selectedSlots.add(slot);
                    } else {
                      selectedSlots.remove(slot);
                    }
                  });
                },
              );
            }).toList(),
            const Divider(),
            const Text("Add Custom Time Slot"),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startTimeController,
                    decoration: const InputDecoration(
                      labelText: "Start Time",
                      hintText: "e.g., 2:00 PM",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: endTimeController,
                    decoration: const InputDecoration(
                      labelText: "End Time",
                      hintText: "e.g., 3:00 PM",
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: addCustomSlot,
              child: const Text("Add Custom Slot"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedSlots),
          child: const Text("Apply"),
        ),
      ],
    );
  }
}
