import 'package:flutter/material.dart';
import 'package:medconnect/main_layout.dart';
import 'package:medconnect/screens/Doctors/Appointment/appointment_details_page.dart';
import 'package:medconnect/screens/Patients/Appointment/appointment_screen.dart';
import 'package:medconnect/screens/Patients/Appointment/booking_page.dart';
import 'package:medconnect/screens/Patients/Appointment/success_booked.dart';
import 'package:medconnect/screens/auth/choose_user_role.dart';
import 'package:medconnect/screens/auth/doctor_sign_up.dart';
import 'package:medconnect/screens/auth/patient_sign_up.dart';

class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String chooseUserRole = '/choose-user-role';
  static const String selectLanguage = '/select-language';
  static const String role = '/role';
  static const String doctorSignUp = '/doctor-sign-up';
  static const String patientSignUp = '/patient-sign-up';
  static const String main = 'main';
  static const String appointments = '/appointments';
  static const String booking = '/booking';
  static const String successBooking = '/success-booking';
  static const String doctorAppointments = '/doctor-appointments';

  static Map<String, WidgetBuilder> get routes {
    return {
      role: (context) => const ChooseUserRole(),
      doctorSignUp: (context) => const DoctorSignUp(),
      patientSignUp: (context) => const PatientSignUp(),
      main: (context) => const MainLayout(),
      appointments: (context) =>  AppointmentScreen(),
      booking: (context) => const BookingPage(),
      successBooking: (context) => const SuccessBooked(date: '', time: '', doctorName: '',),
      doctorAppointments: (context) => AppointmentDetailsPage(patientId: '',
        appointmentDate: DateTime(2023, 10, 1), // Example date
        name: 'John Doe', // Example name
        appointmentTime: '10:00 AM', // Example time
        appointmentId: '12345', // Example ID
      ),

      // home: (context) => const Home(),
      // login: (context) => const Login(),
      // register: (context) => const Register(),
      // forgotPassword: (context) => const ForgotPassword(),
      // chooseUserRole: (context) => const ChooseUserRole(),
      // selectLanguage: (context) => const SelectLanguage(),
    };
  }

}






