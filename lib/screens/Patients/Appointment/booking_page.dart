import 'package:flutter/material.dart';
import 'package:medconnect/components/button.dart';
import 'package:medconnect/components/custom_appbar.dart';
import 'package:medconnect/models/booking_datetime_converted.dart';
import 'package:medconnect/providers/dio_provider.dart';
import 'package:medconnect/utils/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // Declaration
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusDay = DateTime.now();
  DateTime _currentDay = DateTime.now();
  int? _currentIndex;
  bool _isWeekend = false;
  bool _dateSelected = (DateTime.now().weekday != DateTime.saturday &&
      DateTime.now().weekday != DateTime.sunday);
  bool _timeSelected = false;
  String? token;
  List<int> blockedSlots = [];
  List<int> bookedSlots = [];
  String? userRole;
  List<Map<String, dynamic>> serverBlockedSlots =
      []; // Store blocked slots from the server
  String? doctorId; // Store the doctor's ID
  String? doctorName; // Optionally store the doctor's name
  DateTime? preFilledDate;
  String? preFilledTime;
  String? appointmentId = '';

  Future<void> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt') ?? '';
  }

  Future<void> fetchBlockedAndBookedSlots() async {
    try {
      final getDate =
          DateConverted.getDate(_currentDay); // Get the selected date
      if (doctorId == null) {
        throw Exception('Doctor ID is missing');
      }

      final response = await DioProvider()
          .getBlockedAndBookedSlots(token!, getDate, doctorId!);

      if (response != 'Error') {
        setState(() {
          blockedSlots = response['blockedSlots'].map<int>((time) {
            // Convert time string to an index for UI mapping
            final hour = int.parse(time.split(':')[0]);
            final minute = int.parse(time.split(':')[1].split(' ')[0]);
            return (hour - 9) * 2 + (minute == 30 ? 1 : 0); // Map to slot index
          }).toList();

          bookedSlots = response['bookedSlots'].map<int>((time) {
            // Convert time string to an index for UI mapping
            final hour = int.parse(time.split(':')[0]);
            final minute = int.parse(time.split(':')[1].split(' ')[0]);
            return (hour - 9) * 2 + (minute == 30 ? 1 : 0); // Map to slot index
          }).toList();
        });
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching slots: $e')),
        );
      });
    }
  }

  Future<void> fetchDoctorBlockedSlots() async {
    try {
      final response = await DioProvider().getDoctorBlockedSlots(token!);
      setState(() {
        serverBlockedSlots = response.map<Map<String, dynamic>>((slot) {
          return {
            'date': slot['date'],
            'day': slot['day'],
            'time': slot['time'],
          };
        }).toList();
        // Filter slots for the currently selected date.  Crucially, we do *not*
        // convert to indices here.  We keep the server representation.
        serverBlockedSlots = serverBlockedSlots.where((slot) {
          final slotDate = DateTime.parse(slot['date']);
          return slotDate.year == _currentDay.year &&
              slotDate.month == _currentDay.month &&
              slotDate.day == _currentDay.day;
        }).toList();
        blockedSlots = serverBlockedSlots.map((slot) {
          // Convert time string to an index for UI mapping
          final timeString = slot['time'] as String;
          final hour = int.parse(timeString.split(':')[0]);
          final minute = int.parse(timeString.split(':')[1].split(' ')[0]);
          return (hour - 9) * 2 + (minute == 30 ? 1 : 0); // Map to slot index
        }).toList();
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching blocked slots: $e')),
        );
      });
    }
  }

  Future<void> getUserRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    userRole = prefs.getString('userRole');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)!.settings.arguments;
      if (arguments != null && arguments is Map<String, dynamic>) {
        setState(() {
          doctorId = arguments['doctorId'] ?? ''; // Retrieve the doctor's ID
          doctorName = arguments['doctorName'] ?? 'Unknown Doctor'; // Retrieve the doctor's name
          preFilledDate = arguments['preFilledDate']; // Retrieve pre-filled date
          preFilledTime = arguments['preFilledTime']; // Retrieve pre-filled time
          appointmentId = arguments['appointmentId']; // Retrieve appointment ID
        });
      } else {
        debugPrint('doctorId is missing in arguments');
      }

      // Fetch user role and slots after doctorId is set
      if (doctorId != null && doctorId!.isNotEmpty) {
        getToken().then((_) {
          getUserRole().then((_) {
            if (userRole == 'doctor') {
              fetchDoctorBlockedSlots();
            } else {
              fetchBlockedAndBookedSlots();
            }
          });
        });
      } else {
        debugPrint('Cannot fetch slots: doctorId is null or empty');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No need to set doctorId here anymore
  }

  void _evaluateWeekend(DateTime date) {
    setState(() {
      _isWeekend = (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday);
      if (_isWeekend) {
        _timeSelected = false;
        _currentIndex = null;
      } else {
        // Ensure doctorId is set before calling fetchBlockedAndBookedSlots
        if (doctorId != null && doctorId!.isNotEmpty) {
          if (userRole == 'doctor') {
            fetchDoctorBlockedSlots();
          } else {
            fetchBlockedAndBookedSlots();
          }
        } else {
          debugPrint('Cannot fetch slots: doctorId is null or empty');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Config().init(context);
    final arguments = ModalRoute.of(context)!.settings.arguments;
    Map<String, dynamic> doctor;
    if (arguments is Map<String, dynamic>) {
      doctor = arguments;
    } else {
      doctor = {};
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: CustomAppBar(
        appTitle:
            userRole == 'doctor' ? 'Block Time' : 'Reschedule Appointment',
        icon: const FaIcon(Icons.arrow_back_ios),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 20,
                    vertical: isSmallScreen ? 10 : 20,
                  ),
                  child: Column(
                    children: <Widget>[
                      _tableCalendar(),
                      const SizedBox(height: 25),
                      const SizedBox(height: 15),
                      if (preFilledDate != null && preFilledTime != null)
                        Text(
                          'Current Appointment: ${DateConverted.getDate(preFilledDate!)} at $preFilledTime',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      const SizedBox(height: 15),
                      Text(
                        userRole == 'doctor'
                            ? 'Blocking time slots for patients'
                            : 'Rescheduling appointment with Dr. $doctorName',
                      ),
                    ],
                  ),
                ),
              ),
              userRole == 'doctor'
                  ? _blockTimeUI(isSmallScreen)
                  : _appointmentSlotsUI(isSmallScreen),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 20,
                    vertical: isSmallScreen ? 40 : 60,
                  ),
                  child: Button(
                    width: double.infinity,
                    title: 'Confirm Reschedule',
                    onPressed: () async {
                      final getDate = DateFormat('yyyy-MM-dd').format(_currentDay); // Format date as YYYY-MM-DD
                      final getTime = DateConverted.getTime(_currentIndex!);

                      if (getTime == 'Invalid Time') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid time slot selected')),
                        );
                        return;
                      }

                      Map<String, dynamic> rescheduleData = {
                        'appointmentId': appointmentId, // Use doctorId as appointmentId
                        'newDate': getDate, // Send date in YYYY-MM-DD format
                        'newTime': getTime,
                        'initiator': 'patient', // Ensure initiator is set
                        'token': token,
                      };

                      try {
                        final response = await DioProvider().rescheduleAppointment(rescheduleData);
                        if (response.statusCode == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Appointment rescheduled successfully')),
                          );
                          Navigator.pop(context); // Go back to the previous page
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    disable: !_timeSelected || !_dateSelected,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Table calendar
  Widget _tableCalendar() {
    return TableCalendar(
      focusedDay: _focusDay.isBefore(DateTime.now())
          ? DateTime.now()
          : _focusDay, // Ensure focusedDay is valid
      firstDay: DateTime.now(),
      lastDay: DateTime(2028, 12, 31),
      calendarFormat: _format,
      currentDay: _currentDay,
      rowHeight: 48,
      calendarStyle: const CalendarStyle(
        todayDecoration:
            BoxDecoration(color: Config.primaryColor, shape: BoxShape.circle),
      ),
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.week: 'Week',
      },
      onFormatChanged: (format) {
        setState(() {
          _format = format;
        });
      },
      onDaySelected: ((selectedDay, focusedDay) {
        setState(() {
          _currentDay = selectedDay;
          _focusDay = focusedDay.isBefore(DateTime.now())
              ? DateTime.now()
              : focusedDay; // Ensure focusedDay is valid
          _dateSelected = true;
        });
        _evaluateWeekend(
            selectedDay); // Re-evaluate if the selected day is a weekend
      }),
    );
  }

  Widget _blockTimeUI(bool isSmallScreen) {
    return _isWeekend
        ? SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 20,
                vertical: isSmallScreen ? 30 : 40,
              ),
              child: const Text(
                'Weekends are not available for blocking.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 20,
                vertical: isSmallScreen ? 10 : 20,
              ),
              child: Column(
                children: [
                  const Text(
                    'Block Time Slots',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          16, // Dynamically adjust based on available slots
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isSmallScreen ? 4 : 6,
                        childAspectRatio: isSmallScreen ? 1.5 : 2,
                      ),
                      itemBuilder: (context, index) {
                        final String time =
                            DateConverted.getTime(index); // Get time string
                        // Check if this time slot is in the serverBlockedSlots for the current day
                        final isServerBlocked = serverBlockedSlots.any((slot) =>
                            slot['date'] ==
                                DateConverted.getDate(_currentDay) &&
                            slot['time'] == time);

                        bool isLocallyBlocked = blockedSlots
                            .contains(index); //check if it is locally blocked.

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isServerBlocked) {
                                // Allow unblocking: Remove from serverBlockedSlots and blockedSlots
                                serverBlockedSlots.removeWhere((slot) =>
                                    slot['date'] ==
                                        DateConverted.getDate(_currentDay) &&
                                    slot['time'] == time);
                                blockedSlots.remove(index);
                              } else {
                                if (blockedSlots.contains(index)) {
                                  blockedSlots.remove(index);
                                } else {
                                  blockedSlots.add(index);
                                }
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(15),
                              color: isServerBlocked
                                  ? Colors.red // Blocked by server, priority.
                                  : isLocallyBlocked
                                      ? Colors.red
                                      : Colors.green, // Free slots in green
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              time,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isServerBlocked || isLocallyBlocked
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _appointmentSlotsUI(bool isSmallScreen) {
    return _isWeekend
        ? SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 20,
                vertical: isSmallScreen ? 30 : 40,
              ),
              alignment: Alignment.center,
              child: const Text(
                'Weekend is not available, please select another date',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : 20,
              vertical: isSmallScreen ? 10 : 20,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final String time =
                      DateConverted.getTime(index); // Get the time string
                  final isBlocked =
                      blockedSlots.contains(index); // Check if blocked
                  final isBooked =
                      bookedSlots.contains(index); // Check if booked

                  return InkWell(
                    splashColor: Colors.transparent,
                    onTap: isBlocked || isBooked
                        ? null // Disable interaction for blocked or booked slots
                        : () {
                            setState(() {
                              _currentIndex = index;
                              _dateSelected = true;
                              _timeSelected = true;
                            });
                          },
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.black,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        color: isBlocked
                            ? Colors.red // Blocked slots in red
                            : isBooked
                                ? Colors.orange // Booked slots in orange
                                : _currentIndex == index
                                    ? Config.primaryColor // Selected slot
                                    : Colors.green, // Free slots in green
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        time,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isBlocked || isBooked
                              ? Colors.white
                              : _currentIndex == index
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
                childCount: 16, // Dynamically adjust based on available slots
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 4 : 6,
                childAspectRatio: isSmallScreen ? 1.5 : 2,
              ),
            ),
          );
  }
}
