import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MultiDateBooking extends StatefulWidget {
  const MultiDateBooking({Key? key}) : super(key: key);

  @override
  State<MultiDateBooking> createState() => _MultiDateBookingState();
}

class _MultiDateBookingState extends State<MultiDateBooking> {
  List<DateTime> selectedDates = [];
  Map<DateTime, List<String>> timeSlots = {}; // Time slots per date
  final List<String> availableTimeSlots = [
    "9:00 AM - 10:00 AM",
    "10:00 AM - 11:00 AM",
    "11:00 AM - 12:00 PM",
    "1:00 PM - 2:00 PM",
    "2:00 PM - 3:00 PM",
  ];

  void saveToFirebase() async {
    try {
      for (var date in selectedDates) {
        await FirebaseFirestore.instance.collection('bookings').add({
          'date': date.toIso8601String(),
          'timeSlots': timeSlots[date] ?? [],
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bookings saved successfully!")),
      );
      setState(() {
        selectedDates = [];
        timeSlots = {};
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving bookings: $e")),
      );
    }
  }

  void assignTimeSlotsToDate(DateTime date, List<String> slots) {
    setState(() {
      timeSlots[date] = slots;
    });
  }

  void assignTimeSlotsToMultipleDates(List<DateTime> dates, List<String> slots) {
    for (var date in dates) {
      timeSlots[date] = slots;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Multi-Date Booking")),
      body: Column(
        children: [
          // Calendar for selecting multiple dates
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
          ),
          const SizedBox(height: 20),
          // Display selected dates
          if (selectedDates.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: selectedDates.length,
                itemBuilder: (context, index) {
                  final date = selectedDates[index];
                  return ListTile(
                    title: Text(
                      "${date.toLocal()}".split(' ')[0],
                    ),
                    subtitle: Text(
                      timeSlots[date]?.join(', ') ?? 'No time slots assigned',
                    ),
                    onTap: () {
                      // Assign time slots to this date
                      showDialog(
                        context: context,
                        builder: (context) {
                          return SelectTimeDialog(
                            availableTimeSlots: availableTimeSlots,
                            initialSlots: timeSlots[date] ?? [],
                            onSubmit: (slots) {
                              assignTimeSlotsToDate(date, slots);
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          // Assign time slots to multiple dates
          if (selectedDates.length > 1)
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return SelectTimeDialog(
                      availableTimeSlots: availableTimeSlots,
                      onSubmit: (slots) {
                        assignTimeSlotsToMultipleDates(selectedDates, slots);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
              child: const Text("Assign Time Slots to All"),
            ),
          const SizedBox(height: 20),
          // Save bookings
          ElevatedButton(
            onPressed: saveToFirebase,
            child: const Text("Save Bookings"),
          ),
        ],
      ),
    );
  }
}


class SelectTimeDialog extends StatefulWidget {
  final List<String> availableTimeSlots;
  final List<String> initialSlots;
  final Function(List<String>) onSubmit;

  const SelectTimeDialog({
    Key? key,
    required this.availableTimeSlots,
    this.initialSlots = const [],
    required this.onSubmit,
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
            // Predefined Time Slots
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
            // Custom Time Slot Input
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
          onPressed: () => widget.onSubmit(selectedSlots),
          child: const Text("Apply"),
        ),
      ],
    );
  }
}
