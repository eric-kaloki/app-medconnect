import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:medconnect/screens/Patients/Appointment/appointment_details_page.dart';
import 'package:medconnect/utils/config.dart';
import 'package:medconnect/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentCard extends StatelessWidget {
  final String appointmentId; // Field for appointment ID
  final String doctorId; // New field for doctor ID
  final String doctorName;
  final String category;
  final DateTime appointmentDateTime;
  final bool hasAppointment;
  final String time;
  final bool isRescheduled; // New field to indicate rescheduled appointments

  const AppointmentCard({
    super.key,
    required this.appointmentId,
    required this.doctorId, // Add doctorId as a required parameter
    required this.time,
    required this.doctorName,
    required this.category,
    required this.appointmentDateTime,
    this.hasAppointment = false,
    this.isRescheduled = false, // Default to false
  });

  Future<void> _confirmReschedule(BuildContext context) async {
    try {
      final response = await DioProvider().confirmReschedule({
        'appointmentId': appointmentId,
      });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reschedule confirmed successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming reschedule: $e')),
      );
    }
  }

  Future<void> _cancelReschedule(BuildContext context) async {
    try {
      final response = await DioProvider().cancelAppointment({
        'appointmentId': appointmentId,
      });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reschedule canceled successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error canceling reschedule: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasAppointment) {
      return Card(
        color: Colors.grey[200],
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'You have no appointments.',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final isToday = DateTimeComparison(appointmentDateTime).isSameDate(now);
    final isTomorrow = DateTimeComparison(appointmentDateTime)
        .isSameDate(now.add(const Duration(days: 1)));

    return Card(
      color: Config.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Top Row
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      NetworkImage('https://i.pravatar.cc/300'),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. $doctorName',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category.isNotEmpty
                          ? category
                          : 'Specialty not specified',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
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
                  Text(isToday
                      ? 'Today'
                      : isTomorrow
                          ? 'Tomorrow'
                          : DateFormat('EEEE').format(appointmentDateTime)),
                  const SizedBox(width: 5),
                  Text(DateFormat('MMM d, y').format(appointmentDateTime)),
                  const Spacer(),
                  const Icon(Icons.access_alarm, color: Colors.black),
                  const SizedBox(width: 5),
                  Text(time),
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
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final patientName = prefs.getString('patientName') ?? 'Unknown Patient';

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AppointmentDetailsPage(
                            currentUserName: doctorName,
                            patientName: patientName, // Dynamically set patient name
                            appointmentId: appointmentId,
                            appointmentDateTime: appointmentDateTime,
                            category: category,
                            doctorName: doctorName, // Pass doctorName directly
                            doctorId: doctorId, // Pass doctorId directly
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                    context,
                    AppRoutes.booking, // Redirect to the booking page
                    arguments: {
                      'appointmentId': appointmentId, // Pass the appointment ID
                      'doctorId': doctorId, // Pass the doctor ID
                      'doctorName': doctorName, // Pass the doctor's name
                      'preFilledDate': appointmentDateTime, // Pre-fill the date
                      'preFilledTime': time, // Pre-fill the time
                      'initiator': 'patient',
                      'bookingType': 'reschedule', // Indicate that this is a reschedule
                       // Indicate that the patient initiated the reschedule
                    },
                    );
                  
                  },
                  child: const Text(
                      'Reschedule',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (isRescheduled)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _confirmReschedule(context),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => _cancelReschedule(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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

// Extension to compare dates
extension DateTimeComparison on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
