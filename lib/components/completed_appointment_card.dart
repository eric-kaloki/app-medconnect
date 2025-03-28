// completed_appointment_card.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:medconnect/screens/shared/medical_records_screen.dart';
import 'package:medconnect/utils/config.dart';

class CompletedAppointmentCard extends StatelessWidget {
  final String doctorName;
  final String category;
  final DateTime appointmentDateTime; // Store as DateTime object

  const CompletedAppointmentCard({
    Key? key,
    required this.doctorName,
    required this.category,
    required this.appointmentDateTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Config.primaryColor, // Light green for completed appointments
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Top Row
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/300'), // Placeholder image
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Text('Dr. $doctorName',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                    const SizedBox(width: 15),
                    Text(category.isNotEmpty ? category : 'Specialty not specified',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 15),
            // Middle Row
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(FontAwesomeIcons.calendar, color: Colors.black),
                  const SizedBox(width: 5),
                  Text(DateFormat('EEEE').format(appointmentDateTime)),
                  const SizedBox(width: 5),
                  Text(DateFormat('MMM d, y').format(appointmentDateTime)),
                  const Spacer(),
                  const Icon(Icons.access_alarm, color: Colors.black),
                  const SizedBox(width: 5),
                  Text(DateFormat.jm().format(appointmentDateTime)), // Time
                ],
              ),
            ),
            const SizedBox(height: 15),
            // Bottom Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, // Grey color for Join button
                    ),
                     onPressed: () {
                      Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MedicalRecordsScreen(),
            ),
          );
                    },
                    child: const Text(
                      'View',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}