import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medconnect/screens/shared/video_call_page.dart';
import 'package:medconnect/utils/config.dart';
import 'package:medconnect/screens/Doctors/MedicalRecords/modals/diagnosis_modal.dart';
import 'package:medconnect/screens/Doctors/MedicalRecords/modals/prescription_modal.dart';
import 'package:medconnect/screens/Doctors/MedicalRecords/modals/test_results_modal.dart';
import 'package:medconnect/screens/Doctors/MedicalRecords/modals/treatment_plan_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medconnect/providers/dio_provider.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final DateTime appointmentDate;
  final String appointmentTime;
  final String appointmentId;
  final String name;
  final String patientId;

  // Default (or prefilled) values for medical records
  final String diagnosisDefault;
  final String prescriptionDefault;

  const AppointmentDetailsPage({
    Key? key,
    required this.name,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.appointmentId,
    required this.patientId,
    this.diagnosisDefault = "No diagnosis yet.",
    this.prescriptionDefault = "No prescription added.",
  }) : super(key: key);

  @override
  _AppointmentDetailsPageState createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  List<dynamic> diagnoses = [];
  List<dynamic> prescriptions = [];
  List<dynamic> testResults = [];
  List<dynamic> treatmentPlans = [];
  bool isCallInProgress = false; // Track call status

  @override
  void initState() {
    super.initState();
    _fetchMedicalRecords();
  }

  Future<void> _fetchMedicalRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';

    try {
      final dioProvider = DioProvider();
      final fetchedDiagnoses = await dioProvider.fetchDiagnoses(widget.name, token);
      final fetchedPrescriptions = await dioProvider.fetchPrescriptions(widget.name, token);
      final fetchedTestResults = await dioProvider.fetchTestResults(widget.name, token);
      final fetchedTreatmentPlans = await dioProvider.fetchTreatmentPlans(widget.name, token);

      if (mounted) {
        setState(() {
          diagnoses = fetchedDiagnoses;
          prescriptions = fetchedPrescriptions;
          testResults = fetchedTestResults;
          treatmentPlans = fetchedTreatmentPlans;
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
    final now = DateTime.now();
    final isToday = widget.appointmentDate.year == now.year &&
        widget.appointmentDate.month == now.month &&
        widget.appointmentDate.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = widget.appointmentDate.year == tomorrow.year &&
        widget.appointmentDate.month == tomorrow.month &&
        widget.appointmentDate.day == tomorrow.day;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment Details"),
      ),
      body: Column(
        children: [
          // Fixed Card with Doctor & Appointment Info
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
                          widget.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isToday
                              ? "Today"
                              : isTomorrow
                                  ? "Tomorrow"
                                  : DateFormat('EEEE')
                                      .format(widget.appointmentDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          DateFormat('MMM d, y').format(widget.appointmentDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          widget.appointmentTime,
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
          // Fixed ElevatedButton for Video Call
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
                    final recipientId = widget.patientId; // Ensure this is the patient's ID
                    final roomId = widget.appointmentId;

                    print('Debug: Initiating call with the following details:');
                    print('RoomId (String): $roomId');
                    print('SenderId (String): $senderId');
                    print('RecipientId (String): $recipientId');

                    if (recipientId == null || senderId == null) {
                      print('Error: Missing required fields.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to initiate call. Missing data.')),
                      );
                      _updateCallStatus(false); // Reset call status
                      return;
                    }

                    try {
                      final response = await Dio().post(
                        '${Config.apiUrl}/api/appointments/send-invitation', // Ensure the correct API URL
                        data: {
                          'recipientId': recipientId,
                          'callerName': prefs.getString('fullName'),
                          'channelName': roomId,
                        },
                      );

                      print('Debug: API Response Status Code: ${response.statusCode}');
                      print('Debug: API Response Data: ${response.data}');

                      if (response.statusCode == 200) {
                        print('Call invitation sent successfully for roomId: $roomId');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoCallPage(
                              channelName: roomId,
                            ),
                          ),
                        ).then((_) => _updateCallStatus(false)); // Reset call status after call ends
                      } else {
                        print('Error: Failed to send call invitation for roomId: $roomId');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to send call invitation.')),
                        );
                        _updateCallStatus(false); // Reset call status
                      }
                    } catch (e) {
                      print('Error: Exception occurred while sending call invitation for roomId: $roomId. Exception: $e');
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
                          // Diagnosis Tab
                          _buildDiagnosisTab(context),
                          // Prescription Tab
                          _buildPrescriptionTab(context),
                          // Test Results Tab
                          _buildTestResultsTab(context),
                          // Treatment Plan Tab
                          _buildTreatmentPlanTab(context),
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

  Widget _buildDiagnosisTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("History", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Use Expanded and a Scrollable widget for long lists
          Expanded(
            child: diagnoses.isEmpty
                ? const Text("No diagnoses found.")
                : ListView.builder(
                    //shrinkWrap: true, // Remove shrinkWrap
                    itemCount: diagnoses.length,
                    itemBuilder: (context, index) {
                      final diagnosis = diagnoses[index];
                      return Card(
                        // Added Card for better visual separation
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                diagnosis['diagnosis_details'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text("Severity: ${diagnosis['severity']}"),
                              Text(
                                  "Date: ${diagnosis['appointment_date']}"), //show date
                              if (diagnosis['notes'] != null &&
                                  diagnosis['notes'].isNotEmpty) ...[
                                //show notes if not null
                                const SizedBox(height: 4),
                                Text("Notes: ${diagnosis['notes']}"),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10), // Add spacing before the button
          Center(
            child: ElevatedButton(
              onPressed: () async {
                showDiagnosisModal(
                    context,
                    widget.name,
                    widget
                        .appointmentDate); // Pass patient name and appointment date
              },
              child: const Text("Add New Diagnosis"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "History",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: prescriptions.isEmpty
                ? const Text("No prescriptions found.")
                : ListView.builder(
                    itemCount: prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = prescriptions[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prescription['drug_name'] ?? 'Unknown Drug',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text("Dosage: ${prescription['dosage'] ?? 'N/A'}"),
                              Text("Frequency: ${prescription['frequency'] ?? 'N/A'}"),
                              Text("Duration: ${prescription['duration'] ?? 'N/A'}"),
                              if (prescription['special_instructions'] != null &&
                                  prescription['special_instructions'].isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text("Instructions: ${prescription['special_instructions']}"),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: () {
                showPrescriptionModal(context, widget.name, widget.appointmentId);
              },
              child: const Text("Add New Prescription"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "History",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: testResults.isEmpty
                ? const Text("No test results found.")
                : ListView.builder(
                    itemCount: testResults.length,
                    itemBuilder: (context, index) {
                      final testResult = testResults[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                testResult['test_type'] ?? 'Unknown Test',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text("Lab: ${testResult['lab_details'] ?? 'N/A'}"),
                              Text("Findings: ${testResult['findings'] ?? 'N/A'}"),
                              if (testResult['doctor_remarks'] != null &&
                                  testResult['doctor_remarks'].isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text("Remarks: ${testResult['doctor_remarks']}"),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: () {
                showTestResultsModal(context, widget.name, widget.appointmentId);
              },
              child: const Text("Add New Test Result"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentPlanTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "History",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: treatmentPlans.isEmpty
                ? const Text("No treatment plans found.")
                : ListView.builder(
                    itemCount: treatmentPlans.length,
                    itemBuilder: (context, index) {
                      final treatmentPlan = treatmentPlans[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                treatmentPlan['recommended_procedures'] ?? 'No Procedures',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text("Lifestyle: ${treatmentPlan['lifestyle_changes'] ?? 'N/A'}"),
                              Text("Follow-Up: ${treatmentPlan['follow_up_schedule'] ?? 'N/A'}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: () {
                showTreatmentPlanModal(context, widget.name, widget.appointmentId);
              },
              child: const Text("Add New Treatment Plan"),
            ),
          ),
        ],
      ),
    );
  }
}
