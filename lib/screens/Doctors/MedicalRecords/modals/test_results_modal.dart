import 'package:flutter/material.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showTestResultsModal(BuildContext context, String patientName, String appointmentId) {
  final TextEditingController testTypeController = TextEditingController();
  final TextEditingController labDetailsController = TextEditingController();
  final TextEditingController findingsController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: testTypeController,
                decoration: const InputDecoration(labelText: "Test Type"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: labDetailsController,
                decoration: const InputDecoration(labelText: "Lab Details"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: findingsController,
                decoration: const InputDecoration(labelText: "Findings"),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: "Doctor's Remarks"),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('jwt') ?? '';
                  final doctorName = prefs.getString('doctorName') ?? 'Unknown Doctor';

                  final testResultsData = {
                    'patient_name': patientName,
                    'doctor_name': doctorName, // Include doctor_name
                    'appointment_id': appointmentId,
                    'test_type': testTypeController.text,
                    'lab_details': labDetailsController.text,
                    'findings': findingsController.text,
                    'doctor_remarks': remarksController.text,
                  };

                  try {
                    await DioProvider().saveTestResults(testResultsData, token);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Test results saved successfully!")),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error saving test results: $error")),
                    );
                  }
                },
                child: const Text("Save Test Results"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
