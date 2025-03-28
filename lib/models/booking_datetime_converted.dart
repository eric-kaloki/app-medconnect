import 'package:intl/intl.dart';

//this basically is to convert date/day/time from calendar to string
class DateConverted {
  static String getDate(DateTime date) {
    return DateFormat.yMd().format(date);
  }

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
}
