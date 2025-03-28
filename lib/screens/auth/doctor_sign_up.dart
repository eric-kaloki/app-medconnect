import 'package:flutter/material.dart';
import 'package:medconnect/screens/Doctors/main_layout.dart';
import 'package:medconnect/screens/auth/login_screen.dart';
import 'package:medconnect/utils/config.dart';
import 'package:medconnect/components/button.dart';
import 'package:medconnect/providers/dio_provider.dart';

class DoctorSignUp extends StatefulWidget {
  const DoctorSignUp({super.key});

  @override
  DoctorSignUpState createState() => DoctorSignUpState();
}

class DoctorSignUpState extends State<DoctorSignUp> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final DioProvider dioProvider = DioProvider();
  bool obsecurePass = true;

  @override
  Widget build(BuildContext context) {
    Config().init(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 174, 255, 216),
      appBar: AppBar(
        title: const Text("Doctor Sign Up"),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: constraints.maxHeight * 0.1, // Use relative vertical padding
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
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
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.text,
                            cursorColor: Config.primaryColor,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Full Name',
                              labelText: 'Full Name',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.person_outlined),
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
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            cursorColor: Config.primaryColor,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your number';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: '0712345678',
                              labelText: 'Phone Number',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.phone_outlined),
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
                            controller: _licenseController,
                            keyboardType: TextInputType.text,
                            cursorColor: Config.primaryColor,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your license ID';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Medical License ID',
                              labelText: 'License ID',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.card_membership),
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
                                    ? const Icon(Icons.visibility_off_outlined,
                                        color: Colors.black38)
                                    : const Icon(Icons.visibility_outlined,
                                        color: Config.primaryColor),
                              ),
                            ),
                          ),
                          Config.spaceSmall,
                          Button(
                            width: double.infinity,
                            title: 'Sign Up',
                            onPressed: () async {
                              final formState = _formKey.currentState;
                              if (formState == null || !formState.validate()) {
                                return;
                              }

                              // Validate the medical license first
                              final isValidLicense = await dioProvider
                                  .validateMedicalLicense(
                                      _licenseController.text);

                              if (!isValidLicense) {
                                return;
                              }

                              // Proceed with registration if the license is valid
                              final userRegistration =
                                  await dioProvider.registerDoctor(
                                _nameController.text,
                                _emailController.text,
                                _passController.text,
                                _licenseController.text,
                                _phoneController.text,
                              );

                              if (userRegistration) {
                                // Handle successful registration
                                final token = await dioProvider.getToken();
                                await dioProvider.saveToken(token);

                                // Navigate to the home screen
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DoctorMainLayout(),
                                  ),
                                );
                              } else {
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
                                    builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text('Already have an account? Login'),
                          ),
                        ],
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
