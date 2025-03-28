import 'package:flutter/material.dart';
import 'package:medconnect/components/button.dart';
import 'package:medconnect/utils/routes.dart';

class SuccessBooked extends StatelessWidget {
  final String date; // Add a field for date
  final String time; // Add a field for time
  final String doctorName; // Add a field for doctor's name

  const SuccessBooked({
    super.key,
    required this.date,
    required this.time,
    required this.doctorName,
  });

  @override
  Widget build(BuildContext context) {
     final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String date = args['date'];
    final String time = args['time'];
    final String doctorName = args['doctorName'];
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Successfully Booked',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Doctor: $doctorName'),
                      Text('Date: $date'),
                      Text('Time: $time'),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Back to home page
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: Button(
                width: double.infinity,
                title: 'Back to Home Page',
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.main),
                disable: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}