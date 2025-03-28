import 'package:flutter/material.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prescriptions"),
        centerTitle: true,
      ),
      body:const SafeArea(child: Column(
        children: [
          Text("Listview of prescription to tap, for detailed prescription")
        ],
      )),
    );
  }
}