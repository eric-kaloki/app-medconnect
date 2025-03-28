import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RescheduledAppointmentCard extends StatefulWidget {
  final String patientName;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String appointmentId;
  final String doctorId;
  final String status;

  const RescheduledAppointmentCard({
    Key? key,
    required this.patientName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.appointmentId,
    required this.doctorId,
    required this.status,
  }) : super(key: key);

  @override
  State<RescheduledAppointmentCard> createState() =>
      _RescheduledAppointmentCardState();
}

class _RescheduledAppointmentCardState
    extends State<RescheduledAppointmentCard> {
  Future<void> _confirmReschedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt') ?? '';
      final response = await DioProvider().confirmReschedule({
        'appointmentId': widget.appointmentId,
        "token": token,
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';
    try {
      final response = await DioProvider().cancelAppointment({
        'appointmentId': widget.appointmentId,
        "token": token,
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
    return Card(
      color: Colors.orange[100],
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
                  Text(DateFormat('EEEE').format(widget.appointmentDate)),
                  const SizedBox(width: 5),
                  Text(DateFormat('MMM d, y').format(widget.appointmentDate)),
                  const Spacer(),
                  const Icon(Icons.access_alarm, color: Colors.black),
                  const SizedBox(width: 5),
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
