// PatientHomeScreen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medconnect/screens/Patients/Appointment/appointment_card.dart';
import 'package:medconnect/components/doctor_card.dart' show DoctorCard;
import 'package:medconnect/providers/dio_provider.dart';
import 'package:medconnect/screens/Patients/Appointment/choose_doctor_page.dart'
    show ChooseDoctorPage;
import 'package:medconnect/screens/auth/login_screen.dart';
import 'package:medconnect/utils/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Map<String, dynamic>> medCategories = [
    {'icon': FontAwesomeIcons.userDoctor, 'category': "General"},
    {'icon': FontAwesomeIcons.heartPulse, 'category': "Cardiology"},
    {'icon': FontAwesomeIcons.lungs, 'category': "Respirations"},
    {'icon': FontAwesomeIcons.hand, 'category': "Dermatology"},
    {'icon': FontAwesomeIcons.tooth, 'category': "Dental"}
  ];
  List<Map<String, dynamic>> doctors = [];
  String userFirstName = '';
  String errorMessage = '';
  List<dynamic> cachedAppointments = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        userFirstName = prefs.getString('firstName') ?? '';
      });
    });
    fetchDoctors();
    fetchCachedAppointments();
  }

  Future<void> fetchCachedAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString("cachedAppointments");

    if (cachedData != null) {
      final decodedData = json.decode(cachedData)['appointments'];
      if (mounted) {
        setState(() {
          cachedAppointments = decodedData;
        });
      }
    } else {
      // Handle the case where no cached appointments are found
      if (mounted) {
        setState(() {
          cachedAppointments = []; // Set an empty list if no cached data is found
        });
      }
    }
  }

  Future<void> fetchDoctors() async {
    try {
      final fetchedDoctors = await DioProvider().fetchDoctors();
      if (mounted) {
        setState(() {
          doctors = fetchedDoctors;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    userFirstName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'profile') {
                        // Navigate to profile settings
                      } else if (value == 'logout') {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.clear();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                          value: 'profile', child: Text('Profile Setting')),
                      PopupMenuItem(value: 'logout', child: Text('Logout')),
                    ],
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundImage:
                          NetworkImage('https://i.pravatar.cc/300'),
                    ),
                  ),
                ],
              ),
              Config.spaceSmall,
              const Text(
                "Categories",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Config.spaceSmall,
              SizedBox(
                height: Config.heightSize * 0.05,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...List<Widget>.generate(
                        medCategories.length,
                        (index) => Card(
                              margin: const EdgeInsets.only(right: 20),
                              color: Config.primaryColor,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    FaIcon(
                                      medCategories[index]['icon'],
                                      color: Colors.white,
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Text(
                                      medCategories[index]['category'],
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                  ],
                ),
              ),
              Config.spaceSmall,
              const Text(
                'Appointment Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Config.spaceSmall,
             Expanded(
  child: Builder(
    builder: (context) {
      // Filter out past appointments
      final upcomingAppointments = cachedAppointments.where((appointment) {
        final appointmentDate = DateTime.parse(appointment['date']);
        return appointmentDate.isAfter(DateTime.now());
      }).toList();
      print(upcomingAppointments);

      // Sort appointments by date in ascending order
      upcomingAppointments.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateA.compareTo(dateB);
      });

      if (upcomingAppointments.isEmpty) {
        return const Center(child: Text("You don't have any upcoming appointments to show"));
      }

      // Display the top two upcoming appointments
      return ListView.builder(
        itemCount: upcomingAppointments.length > 2 ? 2 : upcomingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = upcomingAppointments[index];
            return AppointmentCard(
            hasAppointment: true,
            doctorName: appointment['doctorName'] ?? 'Unknown',
            category: appointment['category'] ?? 'General',
            appointmentDateTime: DateTime.parse(appointment['date']),
            time: appointment['time'] ?? 'Unknown',
            appointmentId: appointment['id'],
            doctorId: appointment['doctor_id'], // Pass doctorId to AppointmentDetailsPage
            );
        },
      );
    },
  ),
),
Config.spaceSmall,
              const Text(
                'Top Doctors',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Config.spaceSmall,
              Config.spaceSmall,
              Expanded(
                child: ListView.builder(
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    return DoctorCard(
                      doctor: doctors[index],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ChooseDoctorPage(),
            ),
          );
        },
        backgroundColor: Config.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
