import 'package:flutter/material.dart';
import 'package:medconnect/screens/auth/login_screen.dart';
import 'package:medconnect/utils/config.dart';
import 'package:medconnect/utils/routes.dart';

class ChooseUserRole extends StatelessWidget {
  const ChooseUserRole({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.primaryColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Register role as",
                        style: TextStyle(
                          color: Color.fromARGB(255, 51, 51, 51),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 60),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(200, 60),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Config.primaryColor),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.doctorSignUp);
                        },
                        child: const Text(
                          'Doctor',
                          style: TextStyle(
                            color: Color.fromARGB(255, 100, 100, 100),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'OR',
                        style: TextStyle(
                          color: Color.fromARGB(255, 100, 100, 100),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(200, 60),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Config.primaryColor),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.patientSignUp);
                        },
                        child: const Text(
                          'Patient',
                          style: TextStyle(
                            color: Color.fromARGB(255, 100, 100, 100),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            color: Color.fromARGB(255, 100, 100, 100),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
