import 'package:flutter/material.dart';
import 'package:medconnect/screens/Doctors/main_layout.dart';
import 'package:medconnect/screens/Patients/main_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('userRole'); // Retrieve the user role
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while the user role is being fetched
    if (userRole == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Conditional rendering based on user role
    return userRole == 'doctor'
        ? const DoctorMainLayout() // Render Doctor Home Screen
        : const PatientMainLayout(); // Render Patient Home Screen
  }
}