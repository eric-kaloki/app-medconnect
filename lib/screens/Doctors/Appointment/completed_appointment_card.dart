// completed_appointment_card.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:medconnect/screens/Doctors/Appointment/appointment_details_page.dart';
import 'package:medconnect/utils/config.dart';

class CompletedAppointmentCard extends StatelessWidget {
  final String patientName;
  final DateTime appointmentDate; // Date only
  final String appointmentTime; // Time
  final String appointmentId;

  const CompletedAppointmentCard({
    super.key,
    required this.patientName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.appointmentId,
    
  });

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
                    Text(patientName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
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
                  Text(DateFormat('EEEE').format(appointmentDate)),
                  const SizedBox(width: 5),
                  Text(DateFormat('MMM d, y').format(appointmentDate)),
                  const Spacer(),
                  const Icon(Icons.access_alarm, color: Colors.black),
                  const SizedBox(width: 5),
                  Text(appointmentTime), // Time
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
                    backgroundColor: Colors.grey, // Grey color for View button
                  ),
                 onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentDetailsPage(
                            name: patientName,
                            appointmentDate: appointmentDate,
                            appointmentTime: appointmentTime,
                            appointmentId: appointmentId, // Replace with actual ID if available
                          ),
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