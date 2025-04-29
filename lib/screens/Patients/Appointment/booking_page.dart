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
  List<Map<String, dynamic>> serverBlockedSlots = [];
  String? doctorId;
  String? doctorName;
  DateTime? preFilledDate;
  String? preFilledTime;
  String? appointmentId = '';
  String _bookingType =
      'new'; // 'new', 'reschedule', or 'block'.  Defaults to 'new'

  Future<void> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt') ?? '';
  }

  Future<void> fetchSlots() async {
    try {
      final getDate = DateConverted.getDate(_currentDay);
      if (doctorId == null) {
        throw Exception('Doctor ID is missing');
      }

      final blockedAndBookedResponse = await DioProvider()
          .getBlockedAndBookedSlots(token!, getDate, doctorId!);

      final doctorBlockedResponse =
          await DioProvider().getDoctorBlockedSlots(token!);

      if (blockedAndBookedResponse != 'Error' &&
          doctorBlockedResponse != 'Error') {
        setState(() {
          // Parse blocked slots, using DateConverted.getTime() for comparison
          blockedSlots = blockedAndBookedResponse['blockedSlots']
              .map<int>((timeString) {
                final index = List.generate(16, (i) => i).firstWhere(
                  (i) => DateConverted.getTime(i) == timeString,
                  orElse: () => -1,
                );
                return index;
              })
              .where((index) => index != -1)
              .toList();

          // Parse booked slots, using DateConverted.getTime() for comparison
          bookedSlots = blockedAndBookedResponse['bookedSlots']
              .map<int>((timeString) {
                final index = List.generate(16, (i) => i).firstWhere(
                  (i) => DateConverted.getTime(i) == timeString,
                  orElse: () => -1,
                );
                return index;
              })
              .where((index) => index != -1)
              .toList();
          // Process doctor-specific blocked slots
          serverBlockedSlots =
              doctorBlockedResponse.map<Map<String, dynamic>>((slot) {
            return {
              'date': slot['date'],
              'day': slot['day'],
              'time': slot['time'],
            };
          }).toList();

          // Filter doctor-specific blocked slots for the current day
          serverBlockedSlots = serverBlockedSlots.where((slot) {
            final slotDate = DateTime.parse(slot['date']);
            return slotDate.year == _currentDay.year &&
                slotDate.month == _currentDay.month &&
                slotDate.day == _currentDay.day;
          }).toList();

          // Merge doctor-specific blocked slots into the blockedSlots list
          blockedSlots.addAll(serverBlockedSlots
              .map((slot) {
                final timeString = slot['time'] as String;
                final index = List.generate(16, (i) => i).firstWhere(
                  (i) => DateConverted.getTime(i) == timeString,
                  orElse: () => -1,
                );
                return index;
              })
              .where((index) => index != -1)
              .toList());
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

  Future<void> getUserRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    userRole = prefs.getString('userRole');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final arguments = ModalRoute.of(context)!.settings.arguments;
      if (arguments != null && arguments is Map<String, dynamic>) {
        setState(() {
          doctorId = arguments['doctorId'] ?? '';
          doctorName = arguments['doctorName'] ?? 'Unknown Doctor';
          preFilledDate = arguments['preFilledDate'];
          preFilledTime = arguments['preFilledTime'];
          appointmentId = arguments['appointmentId'];
          _bookingType = arguments['bookingType'] ?? 'new';
        });
      } else {
        debugPrint('Arguments are missing or invalid');
      }

      await getToken();
      await getUserRole();

      // Fetch slots immediately in initState
      if (doctorId != null && doctorId!.isNotEmpty) {
        await fetchSlots();
      }

      if (preFilledDate != null) {
        _currentDay = preFilledDate!;
        _focusDay = preFilledDate!;
        _dateSelected = true;
      }
      if (preFilledTime != null) {
        _currentIndex = DateConverted.getTimeIndex(preFilledTime!);
        _timeSelected = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _evaluateWeekend(DateTime date) {
    setState(() {
      _isWeekend = (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday);
      if (_isWeekend) {
        _timeSelected = false;
        _currentIndex = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Config().init(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    String appBarTitle = '';
    String buttonTitle = '';

    if (_bookingType == 'new') {
      appBarTitle = 'Book Appointment';
      buttonTitle = 'Confirm Appointment';
    } else if (_bookingType == 'reschedule') {
      appBarTitle = 'Reschedule Appointment';
      buttonTitle = 'Confirm Reschedule';
    } else if (_bookingType == 'block') {
      appBarTitle = 'Block Time Slots';
      buttonTitle = 'Confirm Block Time';
    }

    return Scaffold(
      appBar: CustomAppBar(
        appTitle: appBarTitle,
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
                      if (preFilledDate != null &&
                          preFilledTime != null &&
                          _bookingType != 'block')
                        Text(
                          'Current Appointment: ${DateConverted.getDate(preFilledDate!)} at $preFilledTime',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      const SizedBox(height: 15),
                      Text(
                        _bookingType == 'new'
                            ? 'Book an Appointment with Dr. $doctorName'
                            : _bookingType == 'reschedule'
                                ? 'Rescheduling appointment with Dr. $doctorName'
                                : 'Blocking time slots for patients',
                      ),
                    ],
                  ),
                ),
              ),
              userRole == 'doctor' && _bookingType == 'block'
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
                    title: buttonTitle,
                    onPressed: () async {
                      final getDate = DateFormat('yyyy-MM-dd')
                          .format(_currentDay); // Format date
                      final getTime = _timeSelected && _currentIndex != null
                          ? DateConverted.getTime(_currentIndex!)
                          : null;

                      if (_bookingType == 'block') {
                        if (blockedSlots.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('No time slots selected to block')),
                          );
                          return;
                        }

                        List<Map<String, dynamic>> blockedTimes =
                            blockedSlots.map((index) {
                          final time = DateConverted.getTime(index);
                          return {
                            'date': getDate,
                            'day': DateFormat('EEEE').format(_currentDay),
                            'time': time,
                          };
                        }).toList();

                        try {
                          if (token == null || token!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Authentication token is missing')),
                            );
                            return;
                          }

                          final response = await DioProvider().blockTimeSlots({
                            'blockedSlots': blockedTimes,
                            'token': token,
                          });

                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Time slots blocked successfully')),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to block time slots.')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      } else {
                        if (!_timeSelected || getTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please select a valid time slot.')),
                          );
                          return;
                        }

                        if (_bookingType == 'new') {
                          Map<String, dynamic> appointmentData = {
                            'date': getDate,
                            'day': DateFormat('EEEE').format(_currentDay),
                            'time': getTime,
                            'doctor_id': doctorId,
                          };

                          try {
                            final response = await DioProvider()
                                .bookAppointment(appointmentData, token!);
                            if (response.statusCode == 201) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Appointment booked successfully')),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Failed to book appointment.')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } else if (_bookingType == 'reschedule') {
                          Map<String, dynamic> rescheduleData = {
                            'appointmentId': appointmentId,
                            'newDate': getDate,
                            'newTime': getTime,
                            'initiator': userRole == 'doctor'
                                ? 'doctor'
                                : 'patient', // Set initiator
                            'token': token,
                          };
                          try {
                            final response = await DioProvider()
                                .rescheduleAppointment(rescheduleData);
                            if (response.statusCode == 200) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Appointment rescheduled successfully')),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Failed to reschedule appointment.')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    },
                    disable: (_bookingType == 'block' && !_dateSelected) ||
                        (!_timeSelected &&
                            _bookingType !=
                                'block'), // Disable if no time selected
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
      focusedDay:
          _focusDay.isBefore(DateTime.now()) ? DateTime.now() : _focusDay,
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
      onDaySelected: ((selectedDay, focusedDay) async {
        // Fetch slots when a new day is selected
        setState(() {
          _currentDay = selectedDay;
          _focusDay =
              focusedDay.isBefore(DateTime.now()) ? DateTime.now() : focusedDay;
          _dateSelected = true;
          _timeSelected = false; // Reset time selection when day changes.
          _currentIndex = null;
        });
        _evaluateWeekend(selectedDay);
        if (!_isWeekend && doctorId != null && doctorId!.isNotEmpty) {
          await fetchSlots();
        }
      }),
    );
  }

  Widget _blockTimeUI(bool isSmallScreen) {
    return SliverToBoxAdapter(
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
            if (_isWeekend)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'Weekends are not available for blocking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 16,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isSmallScreen ? 4 : 6,
                    childAspectRatio: isSmallScreen ? 1.5 : 2,
                  ),
                  itemBuilder: (context, index) {
                    final String time =
                        DateConverted.getTime(index); // Get time string
                    final isServerBlocked = serverBlockedSlots.any((slot) =>
                        slot['date'] ==
                            DateFormat('yyyy-MM-dd').format(_currentDay) &&
                        slot['time'] == time);
                    final isLocallyBlocked =
                        blockedSlots.contains(index); // Correct
                    final isBooked =
                        bookedSlots.contains(index); // Check if booked

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isServerBlocked) {
                            // Unblock
                            serverBlockedSlots.removeWhere((slot) =>
                                slot['date'] ==
                                    DateFormat('yyyy-MM-dd')
                                        .format(_currentDay) &&
                                slot['time'] == time);
                            blockedSlots.remove(index);
                          } else {
                            if (blockedSlots.contains(index)) {
                              blockedSlots.remove(index);
                            } else {
                              blockedSlots.add(index);
                            }
                          }
                          _timeSelected = blockedSlots.isNotEmpty;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(15),
                          color: isServerBlocked
                              ? Colors.red
                              : isLocallyBlocked
                                  ? Colors.red
                                  : isBooked
                                      ? Colors.orange
                                      : blockedSlots.contains(index)
                                          ? Config.primaryColor
                                          : Colors.green,
                        // Blocked slots in red, booked slots in orange
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
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 10 : 20,
        vertical: isSmallScreen ? 10 : 20,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final String time =
                DateConverted.getTime(index); // Get the time string
            final isBlocked = blockedSlots.contains(index); // Check if blocked
            final isBooked = bookedSlots.contains(index); // Check if booked

            return InkWell(
              splashColor: Colors.transparent,
              onTap: (isBlocked || isBooked)
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
                    color: _currentIndex == index ? Colors.white : Colors.black,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  color: isBlocked
                      ? Colors.red // Blocked slots in red
                      : isBooked
                          ? Colors.orange // Booked slots in orange
                          : _currentIndex == index
                              ? Config
                                  .primaryColor // Selected slot in primary color
                              : Colors.green, // Available slots in green
                ),
                alignment: Alignment.center,
                child: Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isBlocked || isBooked
                        ? Colors.white // Blocked/Booked slots text in white
                        : _currentIndex == index
                            ? Colors.white // Selected slot text in white
                            : Colors.black, // Available slots text in black
                  ),
                ),
              ),
            );
          },
          childCount: 16,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isSmallScreen ? 4 : 6,
          childAspectRatio: isSmallScreen ? 1.5 : 2,
        ),
      ),
    );
  }
}
