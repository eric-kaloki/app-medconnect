import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:medconnect/screens/Doctors/Appointment/appointment_details_page.dart';
import 'package:medconnect/utils/config.dart';
import 'package:medconnect/utils/routes.dart';

class AppointmentCard extends StatefulWidget {
  final String patientName;
  final DateTime appointmentDate; // Date only
  final String appointmentTime; // Time only
  final bool hasAppointment;
  final String appointmentId;
  final bool isRescheduled; // New field to indicate rescheduled appointments
  final String doctorId; // New field for doctor ID
  final String status; // Add status
  final String patientId; // New field for patient ID

  AppointmentCard({
    this.patientId = '',
    this.patientName = '',
    DateTime? appointmentDate,
    this.appointmentTime = '',
    this.hasAppointment = false,
    this.appointmentId = '',
    this.isRescheduled = false, // Default to false
    this.doctorId = '', // Default to empty string
    this.status = '', // Default status
    Key? key,
  })  : appointmentDate = appointmentDate ?? DateTime.now(),
        super(key: key);

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  Future<void> _confirmReschedule() async {
    try {
      final response = await DioProvider().confirmReschedule({
        'appointmentId': widget.appointmentId,
      });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reschedule confirmed successfully')),
        );
        setState(() {
          // Update UI or state as needed
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming reschedule: $e')),
      );
    }
  }

  Future<void> _cancelReschedule() async {
    try {
      final response = await DioProvider().cancelAppointment({
        'appointmentId': widget.appointmentId,
      });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reschedule canceled successfully')),
        );
        setState(() {
          // Update UI or state as needed
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error canceling reschedule: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasAppointment) {
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
    final isToday = widget.appointmentDate.year == now.year &&
        widget.appointmentDate.month == now.month &&
        widget.appointmentDate.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = widget.appointmentDate.year == tomorrow.year &&
        widget.appointmentDate.month == tomorrow.month &&
        widget.appointmentDate.day == tomorrow.day;

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
                  backgroundImage: NetworkImage('https://i.pravatar.cc/300'),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
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
                          : DateFormat('EEEE').format(widget.appointmentDate)),
                  const SizedBox(width: 5),
                  Text(DateFormat('MMM d, y').format(widget.appointmentDate)),
                  const Spacer(),
                  const Icon(Icons.access_alarm, color: Colors.black),
                  const SizedBox(width: 5),
                  // Use the appointmentTime string directly
                  Text(widget.appointmentTime),
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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AppointmentDetailsPage(
                            appointmentDate: widget.appointmentDate,
                            appointmentTime: widget.appointmentTime,
                            name: widget.patientName,
                            appointmentId: widget.appointmentId,
                            patientId: widget.patientId, // Pass the doctor ID
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
                          'appointmentId': widget.appointmentId,
                          'doctorId': widget.doctorId, // Pass the doctor ID
                          'doctorName': widget.patientName, // Pass the patient's name
                          'preFilledDate': widget.appointmentDate, // Pre-fill the date
                          'preFilledTime': widget.appointmentTime, // Pre-fill the time
                          'initiator': 'doctor', // Indicate that the doctor initiated the reschedule
                          'bookingType': 'reschedule', // Indicate that this is a reschedule
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
            if (widget.isRescheduled)
              // Reschedule confirmation buttons.  These are shown when the appointment is in a rescheduled state.
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: _confirmReschedule,
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
                      onPressed: _cancelReschedule,
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
