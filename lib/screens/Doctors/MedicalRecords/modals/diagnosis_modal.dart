import 'package:flutter/material.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showDiagnosisModal(BuildContext context, String patientName, DateTime appointmentDate) {
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController severityController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

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
                controller: diagnosisController,
                decoration: const InputDecoration(labelText: "Diagnosis Details"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: severityController,
                decoration: const InputDecoration(labelText: "Severity"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: "Notes"),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('jwt') ?? '';
                  final doctorName = prefs.getString('doctorName') ?? 'Unknown Doctor';

                  final diagnosisData = {
                    'patient_name': patientName,
                    'doctor_name': doctorName,
                    'appointment_date': "${appointmentDate.year}-${appointmentDate.month.toString().padLeft(2, '0')}-${appointmentDate.day.toString().padLeft(2, '0')}",
                    'diagnosis_details': diagnosisController.text,
                    'severity': severityController.text,
                    'notes': notesController.text,
                  };

                  try {
                    await DioProvider().saveDiagnosis(diagnosisData, token);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Diagnosis saved successfully!")),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error saving diagnosis: $error")),
                    );
                  }
                },
                child: const Text("Save Diagnosis"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
