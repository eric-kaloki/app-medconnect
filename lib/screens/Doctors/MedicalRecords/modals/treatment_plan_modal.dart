import 'package:flutter/material.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showTreatmentPlanModal(BuildContext context, String patientName, String appointmentId) {
  final TextEditingController proceduresController = TextEditingController();
  final TextEditingController lifestyleController = TextEditingController();
  final TextEditingController followUpController = TextEditingController();

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
                controller: proceduresController,
                decoration: const InputDecoration(
                  labelText: "Recommended Procedures",
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: lifestyleController,
                decoration: const InputDecoration(
                  labelText: "Lifestyle Changes",
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: followUpController,
                decoration: const InputDecoration(
                  labelText: "Follow-Up Schedule",
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('jwt') ?? '';
                  final doctorName = prefs.getString('doctorName') ?? 'Unknown Doctor';

                  final treatmentPlanData = {
                    'patient_name': patientName,
                    'doctor_name': doctorName, // Include doctor_name
                    'appointment_id': appointmentId,
                    'recommended_procedures': proceduresController.text,
                    'lifestyle_changes': lifestyleController.text,
                    'follow_up_schedule': followUpController.text,
                  };

                  try {
                    await DioProvider().saveTreatmentPlan(treatmentPlanData, token);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Treatment plan saved successfully!")),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error saving treatment plan: $error")),
                    );
                  }
                },
                child: const Text("Save Treatment Plan"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
