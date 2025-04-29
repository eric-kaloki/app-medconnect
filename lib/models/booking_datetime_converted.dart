import 'package:intl/intl.dart';

class DateConverted {
  // Formats a DateTime object into a string with the format 'yyyy-MM-dd'.
  static String getDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Converts a day number (1-7) to its corresponding day name.
  static String getDay(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Sunday';
    }
  }

  static String getTime(int time) {
    switch (time) {
      case 0:
        return '9:00 AM';
      case 1:
        return '9:30 AM';
      case 2:
        return '10:00 AM';
      case 3:
        return '10:30 AM';
      case 4:
        return '11:00 AM';
      case 5:
        return '11:30 AM';
      case 6:
        return '12:00 PM';
      case 7:
        return '12:30 PM';
      case 8:
        return '1:00 PM';
      case 9:
        return '1:30 PM';
      case 10:
        return '2:00 PM';
      case 11:
        return '2:30 PM';
      case 12:
        return '3:00 PM';
      case 13:
        return '3:30 PM';
      case 14:
        return '4:00 PM';
      case 15:
        return '4:30 PM';
      default:
        return 'Invalid Time';
    }
  }

  // Updates the getTimeIndex method to handle AM/PM time strings.
  static int getTimeIndex(String time) {
    try {
      final parsedTime = DateFormat.jm().parse(time); // Parse "4:00 PM"
      final hour = parsedTime.hour;
      final minute = parsedTime.minute;

      if (hour < 9 || hour > 16 || (minute != 0 && minute != 30)) {
        return -1; // Out of range
      }
      return (hour - 9) * 2 + (minute == 30 ? 1 : 0);
    } catch (e) {
      print('Error parsing time: $time, $e');
      return -1; // Invalid format
    }
  }
}
