import 'package:intl/intl.dart';

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String formatDateLong(DateTime date) {
  return DateFormat('EEEE, MMMM d').format(date);
}

String formatDateShort(DateTime date) {
  return DateFormat('MMM d').format(date);
}

int daysBetween(DateTime from, DateTime to) {
  return to.difference(from).inDays;
}

bool isToday(DateTime date) {
  final now = DateTime.now();
  return isSameDay(date, now);
}

String daysAgo(DateTime date) {
  final days = daysBetween(date, DateTime.now());
  if (days == 0) return "Today";
  if (days == 1) return "Yesterday";
  return "$days days ago";
}

String daysUntil(DateTime date) {
  final days = daysBetween(date, DateTime.now());
  if (days == 1) return "Tomorrow";
  if (days == 0) return "Today";
  return "in $days days";
}