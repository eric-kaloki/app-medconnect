import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medconnect/utils/config.dart';

class DioProvider {
  final Dio _dio = Dio();

  DioProvider() {
    _dio.options.baseUrl =
        Config.apiUrl; // Ensure your API URL is defined in Config
    // _dio.options.connectTimeout = const Duration(milliseconds: 5000);
    // _dio.options.receiveTimeout = const Duration(milliseconds: 10000);
  }
  //register new user
  Future<dynamic> registerDoctor(String fullname, String email, String password,
      String licenseId, String phoneNumber) async {
    try {
      var user = await _dio.post('/api/auth/doctor/register', data: {
        'name': fullname,
        'email': email,
        'password': password,
        'licenseId': licenseId,
        'phone': phoneNumber
      });
      if (user.statusCode == 201 && user.data != '') {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return error;
    }
  }

  // Validate license
  Future<bool> validateMedicalLicense(String license) async {
    try {
      var response = await _dio.post('/api/auth/doctor/validate-license',
          data: {'licenseId': license});

      if (response.statusCode == 200) {
        return response
            .data['valid']; // Assuming the response contains a 'valid' field
      } else {
        return false;
      }
    } catch (error) {
      return false; // Handle error appropriately
    }
  }

  Future<dynamic> registerPatient(String fullname, String email,
      String password, String phoneNumber) async {
    try {
      var user = await _dio.post('/api/auth/patient/register', data: {
        'name': fullname,
        'email': email,
        'password': password,
        'phone': phoneNumber
      });
      if (user.statusCode == 201 && user.data != '') {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return error;
    }
  }

  // Get Token
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt') ?? '';
  }

  /// Save token to local storage
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Function to handle user login
  Future<Map<String, dynamic>?> login(String email, String password, {String? fcmToken}) async {
    try {
      var response = await _dio.post('/api/auth/login',
          data: {'email': email, 'password': password, 'fcmToken': fcmToken});

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        // Save the user's role and email
        await prefs.setString('role', response.data['data']['role']);
        await prefs.setString('email', response.data['data']['email']);

        // Save the user's name for display purposes
        String fullName = response.data['data']['name'];
        if (response.data['data']['role'] == 'doctor') {
          await prefs.setString('doctorName', fullName);
        } else {
          await prefs.setString('patientName', fullName);
        }

        String firstName = fullName.split(' ')[0];
        return {
          'success': true,
          'data': {
            'firstName': firstName,
            ...response.data['data'],
          },
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'An error occurred',
      };
    }
  }

  Future<dynamic> storeReviews(Map<String, dynamic> reviewData) async {
    try {
      var response = await _dio.post('/api/reviews', data: reviewData);
      if (response.statusCode == 200) {
        return response.data; // Handle successful response
      } else {
        return null; // Handle unsuccessful response
      }
    } catch (error) {
      return error; // Handle error
    }
  }



  Future<List<Map<String, dynamic>>> fetchDoctors() async {
    try {
      final response = await _dio.get(
          '/api/auth/doctor/get-doctors'); // Ensure this is the correct endpoint
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['doctors']);
        // Access the 'doctors' key
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching doctors: $e');
    }
  }

  Future<Response> bookAppointment(
      Map<String, dynamic> appointmentData, String token) async {
    try {
      final response = await _dio.post(
        '/api/appointments/book',
        data: appointmentData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } catch (e) {
      throw Exception('Failed to book appointment: $e');
    }
  }

  Future<dynamic> getAppointments(String token) async {

    try {
      final response = await _dio.get(
        '/api/appointments/patient-appointments',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode == 200) {
        return response.data; // Expecting a JSON list of appointments
      } else {
        return 'Error';
      }
    } catch (e) {
      return 'Error';
    }
  }



  Future<dynamic> fetchDoctorAppointments(String token, {bool useCache = false}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  if (useCache) {
    String? cachedData = prefs.getString("cachedDoctorAppointments");
    if (cachedData != null) {
      return json.decode(cachedData);
    }
  }

  try {
    final response = await _dio.get(
      '/api/appointments/doctor-appointments',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode == 200) {
      // Cache the fetched data
      await prefs.setString("cachedDoctorAppointments", json.encode(response.data));
      return response.data;
    } else {
      throw Exception(
          'Failed to fetch appointments. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching appointments: $e');
  }
}

  // Save Diagnosis
  Future<void> saveDiagnosis(Map<String, dynamic> diagnosisData, String token) async {
    try {
      final response = await _dio.post(
        '/api/records/new-diagnosis',
        data: diagnosisData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to save diagnosis. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error saving diagnosis: $error');
    }
  }

  // Save Prescription
  Future<void> savePrescription(Map<String, dynamic> prescriptionData, String token) async {
    try {
      final response = await _dio.post(
        '/api/records/new-prescription',
        data: prescriptionData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to save prescription. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error saving prescription: $error');
    }
  }

  // Save Test Results
  Future<void> saveTestResults(Map<String, dynamic> testResultsData, String token) async {
    try {
      final response = await _dio.post(
        '/api/records/test-results',
        data: testResultsData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to save test results. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error saving test results: $error');
    }
  }

  // Save Treatment Plan
  Future<void> saveTreatmentPlan(Map<String, dynamic> treatmentPlanData, String token) async {
    try {
      final response = await _dio.post(
        '/api/records/treatment-plans',
        data: treatmentPlanData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to save treatment plan. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error saving treatment plan: $error');
    }
  }

  // Fetch Diagnoses
  Future<List<dynamic>> fetchDiagnoses(String patientName, String token) async {
    try {
      final response = await _dio.get(
        '/api/records/diagnoses',
        queryParameters: {'patient_name': patientName},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (error) {
      throw Exception('Error fetching diagnoses: $error');
    }
  }

  // Fetch Prescriptions
  Future<List<dynamic>> fetchPrescriptions(String patientName, String token) async {
    try {
      final response = await _dio.get(
        '/api/records/prescriptions',
        queryParameters: {'patient_name': patientName},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (error) {
      throw Exception('Error fetching prescriptions: $error');
    }
  }

  // Fetch Test Results
  Future<List<dynamic>> fetchTestResults(String patientName, String token) async {
    try {
      final response = await _dio.get(
        '/api/records/test-results',
        queryParameters: {'patient_name': patientName},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (error) {
      throw Exception('Error fetching test results: $error');
    }
  }

  // Fetch Treatment Plans
  Future<List<dynamic>> fetchTreatmentPlans(String patientName, String token) async {
    try {
      final response = await _dio.get(
        '/api/records/treatment-plans',
        queryParameters: {'patient_name': patientName},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (error) {
      throw Exception('Error fetching treatment plans: $error');
    }
  }

  // Fetch Medical Records by Patient and Doctor
  Future<Map<String, List<dynamic>>> fetchMedicalRecordsByPatientAndDoctor(
      String patientName, String doctorName, String token) async {
    try {
      final response = await _dio.get(
        '/api/records/records-by-patient-and-doctor',
        queryParameters: {
          'patient_name': patientName,
          'doctor_name': doctorName,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {
        'diagnoses': response.data['diagnoses'] ?? [],
        'prescriptions': response.data['prescriptions'] ?? [],
        'testResults': response.data['testResults'] ?? [],
        'treatmentPlans': response.data['treatmentPlans'] ?? [],
      };
    } catch (error) {
      throw Exception('Error fetching medical records: $error');
    }
  }

  Future<Response> blockTimeSlots(Map<String, dynamic> blockData) async {
    try {
      final response = await _dio.post(
        '/api/appointments/block-slots',
        data: blockData, // Expecting an array of objects with date, day, and time
        options: Options(
          headers: {'Authorization': 'Bearer ${blockData['token']}'},
        ),
      );
      return response;
    } catch (e) {
      throw Exception('Failed to block time slots: $e');
    }
  }

  Future<Map<String, dynamic>> getBlockedAndBookedSlots(String token, String date, String doctorId) async {
    try {
      final response = await _dio.get(
        '/api/appointments/slots',
        queryParameters: {'date': date, 'doctor_id': doctorId}, // Include doctor_id
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode == 200) {
        return response.data; // Return the blocked and booked slots
      } else {
        throw Exception('Failed to fetch slots: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch slots: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDoctorBlockedSlots(String token) async {
    try {
      final response = await _dio.get(
        '/api/appointments/doctor-blocked-slots',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['blockedSlots']);
      } else {
        throw Exception('Failed to fetch blocked slots: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch blocked slots: $e');
    }
  }

  Future<Response> rescheduleAppointment(Map<String, dynamic> rescheduleData) async {
    try {
      final response = await _dio.put(
        '/api/appointments/reschedule',
        data: rescheduleData,
        options: Options(
          headers: {'Authorization': 'Bearer ${rescheduleData['token']}'},
        ),
      );
      return response;
    } catch (e) {
      throw Exception('Failed to reschedule appointment: $e');
    }
  }

  Future<Response> confirmReschedule(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '/api/appointments/confirm-reschedule',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer ${data['token']}'},
        ),
      );
      return response;
    } catch (e) {
      throw Exception('Failed to confirm reschedule: $e');
    }
  }

  Future<Response> cancelAppointment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '/api/appointments/cancel-appointment',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer ${data['token']}'},
        ),
      );
      return response;
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPendingAppointments(String token) async {
    try {
      final response = await _dio.get(
        '/api/appointments/pending-appointments',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['appointments']);
      } else {
        throw Exception('Failed to fetch pending appointments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching pending appointments: $e');
    }
  }
}
