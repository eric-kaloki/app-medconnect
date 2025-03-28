import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:medconnect/utils/config.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({Key? key}) : super(key: key);

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  List<dynamic> diagnoses = [];
  List<dynamic> prescriptions = [];
  List<dynamic> testResults = [];
  List<dynamic> treatmentPlans = [];

  @override
  void initState() {
    super.initState();
    _fetchMedicalRecords();
  }

  Future<void> _fetchMedicalRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';
    final patientName = prefs.getString('patientName') ?? 'Unknown Patient';

    try {
      final dioProvider = DioProvider();
      final fetchedDiagnoses = await dioProvider.fetchDiagnoses(patientName, token);
      final fetchedPrescriptions = await dioProvider.fetchPrescriptions(patientName, token);
      final fetchedTestResults = await dioProvider.fetchTestResults(patientName, token);
      final fetchedTreatmentPlans = await dioProvider.fetchTreatmentPlans(patientName, token);

      if (mounted) {
        setState(() {
          diagnoses = fetchedDiagnoses;
          prescriptions = fetchedPrescriptions;
          testResults = fetchedTestResults;
          treatmentPlans = fetchedTreatmentPlans;
        });
      }
    } catch (error) {
      if (mounted) {
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Records"),
      ),
      body: Column(
        children: [
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
                          _buildDiagnosisTab(context),
                          _buildPrescriptionTab(context),
                          _buildTestResultsTab(context),
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
      child: diagnoses.isEmpty
          ? const Center(child: Text("No diagnoses found."))
          : ListView.builder(
              itemCount: diagnoses.length,
              itemBuilder: (context, index) {
                final diagnosis = diagnoses[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diagnosis['diagnosis_details'] ?? 'No Details',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text("Severity: ${diagnosis['severity'] ?? 'N/A'}"),
                        Text("Date: ${diagnosis['appointment_date'] ?? 'N/A'}"),
                        if (diagnosis['notes'] != null &&
                            diagnosis['notes'].isNotEmpty)
                          Text("Notes: ${diagnosis['notes']}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPrescriptionTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: prescriptions.isEmpty
          ? const Center(child: Text("No prescriptions found."))
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
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text("Dosage: ${prescription['dosage'] ?? 'N/A'}"),
                        Text("Frequency: ${prescription['frequency'] ?? 'N/A'}"),
                        Text("Duration: ${prescription['duration'] ?? 'N/A'}"),
                        if (prescription['special_instructions'] != null &&
                            prescription['special_instructions'].isNotEmpty)
                          Text("Instructions: ${prescription['special_instructions']}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTestResultsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: testResults.isEmpty
          ? const Center(child: Text("No test results found."))
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
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text("Lab: ${testResult['lab_details'] ?? 'N/A'}"),
                        Text("Findings: ${testResult['findings'] ?? 'N/A'}"),
                        if (testResult['doctor_remarks'] != null &&
                            testResult['doctor_remarks'].isNotEmpty)
                          Text("Remarks: ${testResult['doctor_remarks']}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTreatmentPlanTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: treatmentPlans.isEmpty
          ? const Center(child: Text("No treatment plans found."))
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
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
    );
  }
}
