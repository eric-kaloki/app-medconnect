import 'package:flutter/material.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showPrescriptionModal(BuildContext context, String patientName, String appointmentId) {
  final TextEditingController drugNameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();

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
                controller: drugNameController,
                decoration: const InputDecoration(labelText: "Drug Name"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(labelText: "Dosage"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: frequencyController,
                decoration: const InputDecoration(labelText: "Frequency"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: "Duration"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: instructionsController,
                decoration: const InputDecoration(labelText: "Special Instructions"),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('jwt') ?? '';
                  final doctorName = prefs.getString('doctorName') ?? 'Unknown Doctor';

                  final prescriptionData = {
                    'patient_name': patientName,
                    'doctor_name': doctorName, // Include doctor_name
                    'appointment_id': appointmentId,
                    'drug_name': drugNameController.text,
                    'dosage': dosageController.text,
                    'frequency': frequencyController.text,
                    'duration': durationController.text,
                    'special_instructions': instructionsController.text,
                  };

                  try {
                    await DioProvider().savePrescription(prescriptionData, token);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Prescription saved successfully!")),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error saving prescription: $error")),
                    );
                  }
                },
                child: const Text("Save Prescription"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
