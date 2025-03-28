import 'package:flutter/material.dart';
import 'package:medconnect/screens/Doctors/Appointment/appointment_card.dart';
import 'package:medconnect/screens/Doctors/Appointment/rescheduled_appointment_card.dart';
import 'package:medconnect/screens/Patients/Appointment/booking_page.dart';
import 'package:medconnect/screens/auth/login_screen.dart';
import 'package:medconnect/utils/config.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  List<Map<String, dynamic>> appointments = [];
  String userFirstName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this);
    _loadUserFirstName();
    _fetchAppointments();
    _fetchPendingAppointments();
  }

  Future<void> _loadUserFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        userFirstName = prefs.getString('firstName') ?? '';
      });
    }
  }

  Future<void> _fetchAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';

    String? cachedData = prefs.getString("cachedDoctorAppointments");
    if (cachedData != null) {
      _updateAppointments(json.decode(cachedData));
    }

    try {
      final freshData =
          await DioProvider().fetchDoctorAppointments(token, useCache: false);

      await prefs.setString("cachedDoctorAppointments", json.encode(freshData));
      _updateAppointments(freshData);
    } catch (e) {
    }
  }

  Future<void> _fetchPendingAppointments({bool isUpdate = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';

    try {
      final pendingData = await DioProvider().fetchPendingAppointments(token);
      if (mounted) {
        setState(() {
          if (isUpdate) {
            appointments.removeWhere((a) => a['status'] == 'pending');
          }
          appointments.addAll(_mapAppointments(pendingData));
        });
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  void _updateAppointments(dynamic responseData) {
    if (mounted) {
      setState(() {
        appointments = _mapAppointments(responseData);
      });
    }
  }

  List<Map<String, dynamic>> _mapAppointments(dynamic data) {
    List<dynamic> appointmentsList =
        data is Map<String, dynamic> && data.containsKey('appointments')
            ? data['appointments']
            : (data is List<dynamic> ? data : []);

    return appointmentsList.map((appointment) {
      DateTime? appointmentTime;
      try {
        final parsedTime = DateFormat("hh:mm a").parse(appointment['time']);
        final appointmentDate = DateTime.parse(appointment['date']);
        appointmentTime = DateTime(
          appointmentDate.year,
          appointmentDate.month,
          appointmentDate.day,
          parsedTime.hour,
          parsedTime.minute,
        );
      } catch (e) {
        appointmentTime = null;
      }
      final appointmentDate = DateTime.parse(appointment['date']);
      final day = DateFormat('EEEE').format(appointmentDate);

      return {
        'doctorId': appointment['doctor_id'] ?? 'Unknown Doctor',
        'appointmentDate': appointmentDate,
        'appointmentTime': appointmentTime,
        'category': appointment['category'] ?? 'General',
        'patientName': appointment['patientName'] ?? 'Unknown Patient',
        'hasAppointment': appointment['status'] == 'upcoming',
        'appointmentId': appointment['id'] ?? '',
        'status': appointment['status'] ?? 'unknown',
        'initiator': appointment['initiator'] ?? 'Unknown',
        'day': day,
      };
    }).toList();
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove("cachedDoctorAppointments");
      });
    } else if (state == AppLifecycleState.resumed) {
      _fetchAppointments();
      _fetchPendingAppointments(isUpdate: true);
    }
  }

  void _onUpdateTriggered() {
    _fetchPendingAppointments(isUpdate: true);
  }

  Future<String?> _getDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('doctorId');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final validAppointments = appointments.where((appointment) {
      final isToday = appointment['appointmentDate'].day == now.day &&
          appointment['appointmentDate'].month == now.month &&
          appointment['appointmentDate'].year == now.year;
      final isUpcoming = appointment['hasAppointment'] == true &&
          (appointment['appointmentTime']?.isAfter(now) ?? false);
      return (isUpcoming && isToday);
    }).toList();

    final pendingAppointments =
        appointments.where((a) => a['status'] == 'pending').toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final doctorId = await _getDoctorId();
          if (doctorId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Doctor ID not found')),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingPage(),
              settings: RouteSettings(
                arguments: {
                  'doctorId': doctorId,
                  'doctorName': userFirstName,
                },
              ),
            ),
          ).then((_) => _onUpdateTriggered());
        },
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pendingAppointments.isNotEmpty)
                    _buildHorizontalScroll(
                        pendingAppointments), // Horizontal list
                  Config.spaceSmall,
                  _buildVerticalList(validAppointments),
                  Config.spaceSmall,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              userFirstName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'profile', child: Text('Profile Setting')),
                PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
              child: const CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage('https://i.pravatar.cc/300'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Horizontal scrollable list for pending appointments
  Widget _buildHorizontalScroll(List<Map<String, dynamic>> appointments) {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width
    final cardWidth = screenWidth * 0.8; // Set card width to 4/5 of the screen

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rescheduled Appointments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Config.spaceSmall,
        SizedBox(
          height:
              250, // increased height to accommodate RescheduledAppointmentCard
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Container(
                margin: const EdgeInsets.only(right: 10),
                width: cardWidth, // Use the calculated card width
                child: RescheduledAppointmentCard(
                  // Use the RescheduledAppointmentCard
                  patientName: appointment['patientName'],
                  appointmentDate: appointment['appointmentDate'],
                  appointmentTime: appointment['appointmentTime'] != null
                      ? DateFormat.jm().format(appointment['appointmentTime'])
                      : 'Unknown',
                  appointmentId: appointment['appointmentId'],
                  doctorId: appointment['doctorId'],
                  status: appointment['status'],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Vertical list for today's appointments
  Widget _buildVerticalList(List<Map<String, dynamic>> appointments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Appointments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Config.spaceSmall,
        appointments.isEmpty
            ? Card(
                color: Colors.grey[200],
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'You have no appointments today.',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics:
                    const ClampingScrollPhysics(), // Disable nested scrolling
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return AppointmentCard(
                    patientName: appointment['patientName'],
                    appointmentDate: appointment['appointmentDate'],
                    appointmentTime: appointment['appointmentTime'] != null
                        ? DateFormat.jm().format(appointment['appointmentTime'])
                        : 'Unknown',
                    appointmentId: appointment['appointmentId'],
                    hasAppointment: appointment['hasAppointment'],
                    doctorId: appointment['doctorId'],
                    status: appointment['status'],
                  );
                },
              ),
        Config.spaceSmall,
      ],
    );
  }
}
