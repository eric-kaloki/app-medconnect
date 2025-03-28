import 'package:flutter/material.dart';

class DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorCard({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              // Check if there is an image URL, if not use a default.
              backgroundImage: doctor['image'] != null
                  ? NetworkImage(doctor['image'])
                  : const NetworkImage(
                      'https://i.pravatar.cc/300'), // Default Image
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor['name'] ?? 'Unknown', // Display doctor name
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    doctor['category'] ??
                        'Specialty not specified', // Display category
                    style: const TextStyle(color: Colors.grey),
                  ),
                  // Assuming you have a rating field in your doctor data
                  Text(
                    'Rating: ${doctor['rating'] ?? 'N/A'}', // Display rating
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
