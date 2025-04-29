// AppointmentScreen.dart
import 'package:flutter/material.dart';
import 'package:medconnect/screens/Doctors/Appointment/appointment_card.dart'; // Using Patient's Appointment Card
import 'package:medconnect/screens/Doctors/Appointment/canceled_appointment_card.dart';
import 'package:medconnect/screens/Doctors/Appointment/completed_appointment_card.dart';
import 'package:medconnect/providers/dio_provider.dart';
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
  bool _isDisposed = false; // Track whether the widget has been disposed
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
      try {
        final decodedData = json.decode(cachedData)['appointments'];
        if (!_isDisposed && mounted) {
          widget.appointmentsNotifier.value =
              decodedData; // Update the shared state
          setState(() {
            schedules = decodedData;
            AppointmentCache.appointments = decodedData;
          });
        }
      } catch (e) {
        // Optionally clear the invalid cache
        await prefs.remove('cachedAppointments');
      }
    } else if (AppointmentCache.appointments.isNotEmpty) {
      if (!_isDisposed && mounted) {
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
      final response = await DioProvider()
          .fetchDoctorAppointments(token)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Request timed out. Please try again later.');
      });

      if (response == null || response == 'Error') {
        throw Exception('Error fetching appointments from the server.');
      }

      if (!response.containsKey('appointments')) {
        throw Exception('Invalid response format: Missing "appointments" key.');
      }

      final fetchedAppointments =
          List<Map<String, dynamic>>.from(response['appointments']);
      // Update cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("cachedAppointments",
          json.encode({'appointments': fetchedAppointments}));
      AppointmentCache.appointments =
          fetchedAppointments; //update the global variable
      if (!_isDisposed && mounted) {
        widget.appointmentsNotifier.value =
            fetchedAppointments; // Update the shared state
        // Update state
        setState(() {
          schedules = fetchedAppointments;
          appointments =
              fetchedAppointments; // Also update the local appointments list
          isLoading = false; // Stop loading spinner
        });
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          errorMessage = 'Failed to load appointments. Please try again later.';
          isLoading = false; // Stop loading spinner even on error
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadCachedAppointments();
    fetchAppointmentsAndUpdateCache();
  }

  @override
  void dispose() {
    _isDisposed = true; // Mark as disposed
    widget.appointmentsNotifier.dispose();
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
      filteredSchedules = schedules.where((schedule) {
        final appointmentDate = DateTime.parse(schedule['date']);
        return schedule['status'] == 'upcoming' &&
            appointmentDate.isAfter(DateTime.now());
      }).toList();
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
        backgroundColor: Colors.transparent,
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
                                final appointmentDate = DateTime.tryParse(schedule['date'] ?? '') ?? DateTime.now();
                                final appointmentTime = schedule['time'] ?? 'Unknown';
                                final patientName = schedule['patientName'] ?? 'Unknown';
                                final doctorId = schedule['doctor_id'] ?? 'Unknown';
                                final appointmentId = schedule['id'] ?? 'Unknown';
                                final patientId = schedule['patient_id'] ?? 'Unknown';

                                if (schedule['status'] == 'upcoming') {
                                  return AppointmentCard(
                                    hasAppointment: schedule['status'] == 'upcoming', // Set to true if status is 'upcoming'
                                    patientName: patientName,
                                    doctorId: doctorId,
                                    appointmentDate: appointmentDate,
                                    appointmentTime: appointmentTime,
                                    appointmentId: appointmentId,
                                    patientId: patientId, // Pass the patient
                                  );
                                } else if (schedule['status'] == 'complete') {
                                  return CompletedAppointmentCard(
                                    appointmentDate: appointmentDate,
                                    appointmentId: appointmentId,
                                    patientName: patientName,
                                    appointmentTime: appointmentTime,
                                    
                                  );
                                } else if (schedule['status'] == 'cancel') {
                                  return CanceledAppointmentCard(
                                    appointmentDate: appointmentDate,
                                    patientName: patientName,
                                    appointmentTime: appointmentTime,
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
