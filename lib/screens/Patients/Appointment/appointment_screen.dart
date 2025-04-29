// AppointmentScreen.dart
import 'package:flutter/material.dart';
import 'package:medconnect/screens/Patients/Appointment/appointment_card.dart';
import 'package:medconnect/components/canceled_appointment_card.dart';
import 'package:medconnect/components/completed_appointment_card.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:medconnect/screens/Patients/Appointment/choose_doctor_page.dart';
import 'package:medconnect/utils/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A simple global cache for appointments.
class AppointmentCache {
  static List<dynamic> appointments = [];
}

enum FilterStatus { upcoming, complete, cancel }

class AppointmentScreen extends StatefulWidget {
  AppointmentScreen({super.key});

  final ValueNotifier<List<dynamic>> appointmentsNotifier =
      ValueNotifier([]); // Shared state

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;
  String errorMessage = '';

  FilterStatus status = FilterStatus.upcoming;
  List<dynamic> schedules = [];

  /// Load appointments from SharedPreferences or global cache.
  Future<void> loadCachedAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString("cachedAppointments");
    if (cachedData != null) {
      final decodedData = json.decode(cachedData)['appointments'];
      if (mounted) {
        widget.appointmentsNotifier.value =
            decodedData; // Update the shared state
        setState(() {
          schedules = decodedData;
          AppointmentCache.appointments = decodedData;
        });
      }
    } else if (AppointmentCache.appointments.isNotEmpty) {
      if (mounted) {
        widget.appointmentsNotifier.value =
            AppointmentCache.appointments; // Update the shared state
        setState(() {
          schedules = AppointmentCache.appointments;
        });
      }
    }
  }

  /// Fetch appointments from the backend and cache the result.
  Future<void> fetchAppointmentsAndUpdateCache() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await DioProvider().getToken();
      final response = await DioProvider().getAppointments(token);

      if (response == null || response == 'Error') {
        throw Exception('Error fetching appointments from the server.');
      }

      if (!response.containsKey('appointments')) {
        throw Exception('Invalid response format: Missing "appointments" key.');
      }

      setState(() {
        appointments =
            List<Map<String, dynamic>>.from(response['appointments']);
        print('Fetched appointments: $appointments');
        widget.appointmentsNotifier.value =
            appointments; // Update the shared state
        schedules = appointments; // Update schedules with fetched appointments
        AppointmentCache.appointments = appointments; // Update global cache
        isLoading = false;
      });

      // Cache the appointments locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          "cachedAppointments", json.encode({'appointments': appointments}));
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load appointments. Please try again later.';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadCachedAppointments();
    fetchAppointmentsAndUpdateCache(); // Always fetch fresh data
  }

  @override
  void dispose() {
    widget.appointmentsNotifier.dispose(); // Dispose the notifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive adjustments.
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 20.0 : 40.0;
    final titleFontSize = screenWidth < 600 ? 18.0 : 24.0;

    // Filter the appointments based on status.
    List<dynamic> filteredSchedules;
    if (status == FilterStatus.upcoming) {
      print('Schedules: $schedules');
      filteredSchedules = schedules.where((schedule) {
        final appointmentDate = DateTime.parse(schedule['date']);
        final now = DateTime.now();
        return schedule['status'] == 'upcoming' &&
            !appointmentDate.isBefore(
                DateTime(now.year, now.month, now.day)); //corrected line
      }).toList();
      print('Filtered upcoming appointments: $filteredSchedules');
    } else if (status == FilterStatus.complete) {
      filteredSchedules = schedules
          .where((schedule) => schedule['status'] == 'complete')
          .toList();
    } else if (status == FilterStatus.cancel) {
      filteredSchedules = schedules
          .where((schedule) => schedule['status'] == 'cancel')
          .toList();
    } else {
      filteredSchedules = [];
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Appointment Schedule',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: fetchAppointmentsAndUpdateCache,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : appointments.isEmpty
                  ? const Center(child: Text('No appointments found.'))
                  : Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Filter Buttons.
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                for (FilterStatus filterStatus
                                    in FilterStatus.values)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          status = filterStatus;
                                        });
                                      },
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 8.0),
                                          decoration: BoxDecoration(
                                            color: status == filterStatus
                                                ? const Color.fromARGB(
                                                    30, 105, 240, 174)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          child: Text(
                                            filterStatus.name.toUpperCase(),
                                            style: TextStyle(
                                              color: status == filterStatus
                                                  ? Colors.greenAccent
                                                  : Colors.black,
                                              fontWeight: status == filterStatus
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Appointments List.
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredSchedules.length,
                              itemBuilder: (context, index) {
                                var schedule = filteredSchedules[index];
                                if (schedule['status'] == 'upcoming') {
                                  return AppointmentCard(
                                    hasAppointment: true,
                                    doctorName:
                                        schedule['doctorName'] ?? 'Unknown',
                                    doctorId: schedule['doctor_id'] ??
                                        'Unknown', // Corrected key
                                    category: schedule['doctorCategory'] ??
                                        'General', // Corrected key
                                    appointmentDateTime:
                                        DateTime.parse(schedule['date']),
                                    time: schedule['time'] ?? 'Unknown',
                                    appointmentId: schedule['id'],
                                  );
                                } else if (schedule['status'] == 'complete') {
                                  return CompletedAppointmentCard(
                                    doctorName:
                                        schedule['doctorName'] ?? 'Unknown',
                                    category: schedule['category'] ?? 'General',
                                    appointmentDateTime:
                                        DateTime.parse(schedule['date']),
                                  );
                                } else if (schedule['status'] == 'pending') {
                                  return CanceledAppointmentCard(
                                    doctorName:
                                        schedule['doctorName'] ?? 'Unknown',
                                    category: schedule['category'] ?? 'General',
                                    appointmentDateTime:
                                        DateTime.parse(schedule['date']),
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          )
                        ],
                      ),
                    ),
    );
  }
}
