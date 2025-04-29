import 'package:flutter/material.dart';
import 'package:medconnect/screens/Doctors/main_layout.dart';
import 'package:medconnect/screens/Patients/main_layout.dart';
import 'package:medconnect/screens/auth/choose_user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medconnect/utils/config.dart';
import 'package:medconnect/components/button.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// Adjust the import based on your project structure

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final DioProvider dioProvider = DioProvider();
  bool obsecurePass = true;

  @override
  void dispose() {
    // Ensure no navigation logic is executed here
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    Config().init(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 174, 255, 216),
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: constraints.maxHeight * 0.1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Config.spaceSmall,
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              cursorColor: Config.primaryColor,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: 'Email Address',
                                labelText: 'Email',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.email_outlined),
                                prefixIconColor: Config.primaryColor,
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Config.primaryColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Config.primaryColor, width: 2),
                                ),
                              ),
                            ),
                            Config.spaceSmall,
                            TextFormField(
                              controller: _passController,
                              keyboardType: TextInputType.visiblePassword,
                              cursorColor: Config.primaryColor,
                              obscureText: obsecurePass,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Password',
                                labelText: 'Password',
                                alignLabelWithHint: true,
                                prefixIcon: const Icon(Icons.lock_outline),
                                prefixIconColor: Config.primaryColor,
                                border: const OutlineInputBorder(),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Config.primaryColor),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Config.primaryColor, width: 2),
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      obsecurePass = !obsecurePass;
                                    });
                                  },
                                  icon: obsecurePass
                                      ? const Icon(
                                          Icons.visibility_off_outlined,
                                          color: Colors.black38)
                                      : const Icon(Icons.visibility_outlined,
                                          color: Config.primaryColor),
                                ),
                              ),
                            ),
                            Config.spaceSmall,
                            Button(
                              width: double.infinity,
                              title: 'Login',
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    // Retrieve the FCM token
                                    final fcmToken = await FirebaseMessaging.instance.getToken();

                                    final loginResponse = await dioProvider.login(
                                      _emailController.text,
                                      _passController.text,
                                      fcmToken: fcmToken, // Pass the FCM token
                                    );

                                    if (loginResponse != null &&
                                        loginResponse['success']) {
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      String firstName =
                                          loginResponse['data']['firstName'];
                                      await prefs.setString(
                                          'firstName', firstName);
                                           String fullName=
                                          loginResponse['data']['name'];
                                      await prefs.setString(
                                          'fullName', fullName);
                                      String? token =
                                          loginResponse['data']['token'];
                                      String? userRole =
                                          loginResponse['data']['role'];
                                      if (userRole != null) {
                                        await prefs.setString(
                                            'userRole', userRole);
                                      }
                                    if (userRole =='doctor'){
                                      String doctorId = loginResponse['data']['id'];
                                      await prefs.setString('doctorId', doctorId);
                                    }


                                      if (token != null) {
                                        await prefs.setString('jwt', token);
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                userRole == 'doctor'
                                                    ? const DoctorMainLayout()
                                                    : const PatientMainLayout(),
                                          ),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Invalid email or password')),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'An error occurred: $e')),
                                    );
                                  }
                                }
                              },
                              disable: false,
                            ),
                            Config.spaceSmall,
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ChooseUserRole()),
                                );
                              },
                              child: const Text(
                                'Don\'t have an account? Sign Up',
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
