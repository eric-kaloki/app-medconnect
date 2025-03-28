import 'package:flutter/material.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:medconnect/utils/routes.dart';

// Doctor card for the choose doctor page
class DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onBook;

  const DoctorCard({
    Key? key,
    required this.doctor,
    required this.onBook,
  }) : super(key: key);

  // Method to create a row of stars based on the rating
  Widget _buildRatingStars(double rating) {
    int fullStars = rating.round();
    List<Widget> stars = [];

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(const Icon(Icons.star, color: Colors.amber));
      } else {
        stars.add(const Icon(Icons.star_border, color: Colors.amber));
      }
    }

    return Row(children: stars);
  }

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
              backgroundImage: NetworkImage(
                doctor['doctor_profile'] ?? 'https://i.pravatar.cc/300', // Placeholder image
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor['name'] ?? '', // Empty string if not available
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    doctor['specialty'] ?? '', // Empty string if not available
                    style: const TextStyle(color: Colors.grey),
                  ),
                  _buildRatingStars(double.tryParse(doctor['rating']?.toString() ?? '0.0') ?? 3.0), // Call to build stars
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onBook,
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChooseDoctorPage extends StatefulWidget {
  const ChooseDoctorPage({Key? key}) : super(key: key);

  @override
  _ChooseDoctorPageState createState() => _ChooseDoctorPageState();
}

class _ChooseDoctorPageState extends State<ChooseDoctorPage> {
  List<Map<String, dynamic>> doctors = [];
  bool isLoading = true;
  String errorMessage = '';
  final DioProvider dioProvider = DioProvider();

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  // Function to fetch doctors using the DioProvider
  Future<void> fetchDoctors() async {
    try {
      final fetchedDoctors = await dioProvider.fetchDoctors();
      setState(() {
        doctors = fetchedDoctors;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  // Navigate to the BookingPage with the selected doctor's data
  void onBookDoctor(Map<String, dynamic> doctor) {
    Navigator.pushNamed(
      context,
      AppRoutes.booking, // Redirect to the booking page
      arguments: {
        'doctorId': doctor['id'], // Pass the doctor's ID
        'doctorName': doctor['name'], // Pass the doctor's name
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Doctor')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    return DoctorCard(
                      doctor: doctors[index],
                      onBook: () => onBookDoctor(doctors[index]),
                    );
                  },
                ),
    );
  }
}