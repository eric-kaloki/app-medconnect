import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medconnect/screens/shared/video_call_page.dart';
import 'package:medconnect/utils/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String doctorName;
  final String patientName;
  final DateTime appointmentDateTime;
  final String category;
  final String appointmentId;
  final String currentUserName; // The name of the caller
  final String doctorId;

  const AppointmentDetailsPage({
    super.key,
    required this.doctorName,
    required this.patientName,
    required this.appointmentDateTime,
    required this.category,
    required this.appointmentId,
    required this.currentUserName,
    required this.doctorId,
  });

  @override
  _AppointmentDetailsPageState createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  List<dynamic> diagnoses = [];
  List<dynamic> prescriptions = [];
  List<dynamic> testResults = [];
  List<dynamic> treatmentPlans = [];
  late IO.Socket _socket;
  bool isCallInProgress = false; // Track call status

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _fetchMedicalRecords();
  }

  void _initializeSocket() {
    _socket = IO.io(Config.apiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      debugPrint('Connected to WebSocket');
      // Join the room for this appointment
      _socket.emit('join-room', widget.appointmentId);
    });

    _socket.on('invitation-status', (data) {
      debugPrint('Real-time update: $data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call status: ${data['status']}')),
      );
    });

    _socket.on('call-response', (data) {
      debugPrint('Call response: $data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call response: ${data['response']}')),
      );
    });

    _socket.onDisconnect((_) {
      debugPrint('Disconnected from WebSocket');
    });
  }

  @override
  void dispose() {
    _socket.emit('leave-room', widget.appointmentId);
    _socket.dispose();
    super.dispose();
  }

  Future<void> _fetchMedicalRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';

    try {
      final dioProvider = DioProvider();
      final records = await dioProvider.fetchMedicalRecordsByPatientAndDoctor(
        widget.patientName,
        widget.doctorName,
        token,
      );

      if (mounted) {
        setState(() {
          diagnoses = records['diagnoses']!;
          prescriptions = records['prescriptions']!;
          testResults = records['testResults']!;
          treatmentPlans = records['treatmentPlans']!;
        });
      }
    } catch (error) {
      throw Exception('Error fetching medical records: $error');
    }
  }

  void _updateCallStatus(bool status) {
    setState(() {
      isCallInProgress = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isToday = widget.appointmentDateTime.isSameDate(DateTime.now());
    final isTomorrow = widget.appointmentDateTime
        .isSameDate(DateTime.now().add(const Duration(days: 1)));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment Detail"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Doctor & Appointment Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        NetworkImage('https://i.pravatar.cc/300'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctorName, // Display doctorName directly
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.category,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isToday
                              ? "Today"
                              : isTomorrow
                                  ? "Tomorrow"
                                  : DateFormat('EEEE')
                                      .format(widget.appointmentDateTime),
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          DateFormat('MMM d, y').format(widget.appointmentDateTime),
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          DateFormat.jm().format(widget.appointmentDateTime),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Video Call Button triggers the call invitation notification
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Config.primaryColor,
            ),
            onPressed: isCallInProgress
                ? null // Disable button if a call is in progress
                : () async {
                    _updateCallStatus(true); // Set call in progress
                    final prefs = await SharedPreferences.getInstance();
                    final senderId = prefs.getString('jwt');
                    final recipientId = widget.doctorId;
                    final roomId = widget.appointmentId;

                    print('Initiating call. RoomId: $roomId, SenderId: $senderId, RecipientId: $recipientId');

                    if (recipientId == null || senderId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to initiate call. Missing data.')),
                      );
                      _updateCallStatus(false); // Reset call status
                      return;
                    }

                    try {
                      print('${Config.apiUrl}/api/appointments/send-invitation');
                      final response = await Dio().post(
                        '${Config.apiUrl}/api/appointments/send-invitation',
                        data: {
                          'recipientId': recipientId,
                          'callerName': prefs.getString('fullName'),
                          'channelName': roomId,
                        },
                      );

                      if (response.statusCode == 200) {
                        print('Call invitation sent successfully for roomId: $roomId');
                        // Navigate to the video call page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoCallPage(
                              channelName: roomId,
                            ),
                          ),
                        ).then((_) => _updateCallStatus(false)); // Reset call status after call ends
                      } else {
                        print('Failed to send call invitation for roomId: $roomId');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to send call invitation.')),
                        );
                        _updateCallStatus(false); // Reset call status
                      }
                    } catch (e) {
                      print('Error sending call invitation for roomId: $roomId. Error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                      _updateCallStatus(false); // Reset call status
                    }
                  },
            icon: const Icon(Icons.video_call),
            label: const Text("Join Video Call"),
          ),
          const SizedBox(height: 20),
          // Scrollable Card with Tabs
          Expanded(
            child: Card(
              elevation: 2,
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.black,
                      indicatorColor: Config.primaryColor,
                      tabs: [
                        Tab(text: "Diagnosis"),
                        Tab(text: "Prescription"),
                        Tab(text: "Test Results"),
                        Tab(text: "Treatment Plan"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildDiagnosisTab(),
                          _buildPrescriptionTab(),
                          _buildTestResultsTab(),
                          _buildTreatmentPlanTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisTab() {
    return _buildTabContent(
      title: "Diagnosis",
      items: diagnoses,
      itemBuilder: (diagnosis) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diagnosis['diagnosis_details'] ?? 'No details',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text("Severity: ${diagnosis['severity'] ?? 'N/A'}"),
          Text("Date: ${diagnosis['appointment_date'] ?? 'N/A'}"),
          if (diagnosis['notes'] != null && diagnosis['notes'].isNotEmpty)
            Text("Notes: ${diagnosis['notes']}"),
        ],
      ),
    );
  }

  Widget _buildPrescriptionTab() {
    return _buildTabContent(
      title: "Prescription",
      items: prescriptions,
      itemBuilder: (prescription) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prescription['drug_name'] ?? 'Unknown Drug',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text("Dosage: ${prescription['dosage'] ?? 'N/A'}"),
          Text("Frequency: ${prescription['frequency'] ?? 'N/A'}"),
          Text("Duration: ${prescription['duration'] ?? 'N/A'}"),
          if (prescription['special_instructions'] != null &&
              prescription['special_instructions'].isNotEmpty)
            Text("Instructions: ${prescription['special_instructions']}"),
        ],
      ),
    );
  }

  Widget _buildTestResultsTab() {
    return _buildTabContent(
      title: "Test Results",
      items: testResults,
      itemBuilder: (testResult) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            testResult['test_type'] ?? 'Unknown Test',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text("Lab: ${testResult['lab_details'] ?? 'N/A'}"),
          Text("Findings: ${testResult['findings'] ?? 'N/A'}"),
          if (testResult['doctor_remarks'] != null &&
              testResult['doctor_remarks'].isNotEmpty)
            Text("Remarks: ${testResult['doctor_remarks']}"),
        ],
      ),
    );
  }

  Widget _buildTreatmentPlanTab() {
    return _buildTabContent(
      title: "Treatment Plan",
      items: treatmentPlans,
      itemBuilder: (treatmentPlan) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            treatmentPlan['recommended_procedures'] ?? 'No Procedures',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text("Lifestyle: ${treatmentPlan['lifestyle_changes'] ?? 'N/A'}"),
          Text("Follow-Up: ${treatmentPlan['follow_up_schedule'] ?? 'N/A'}"),
        ],
      ),
    );
  }

  Widget _buildTabContent({
    required String title,
    required List<dynamic> items,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: items.isEmpty
          ? Center(child: Text("No $title found."))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: itemBuilder(items[index]),
                  ),
                );
              },
            ),
    );
  }
}

// Extension for date comparison
extension DateTimeComparison on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
