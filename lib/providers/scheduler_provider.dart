import 'package:flutter/material.dart';
import '../models/template.dart';
import '../models/schedule.dart';
import '../utils/logger.dart';

class SchedulerProvider with ChangeNotifier {
  final Map<DateTime, DaySchedule> _schedules = {};
  final List<Template> templates = [
    Template('Default', [
      SongEntry('song1.mp3', const Duration(minutes: 0)),
      SongEntry('song2.mp3', const Duration(minutes: 30)),
    ]),
  ];

  final Logger _logger = Logger();

  int selectedIndex = 0;
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  CalendarFormat calendarFormat = CalendarFormat.month;

  List<String> get logs => _logger.logs;

  void log(String msg) {
    _logger.log(msg);
    notifyListeners();
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay = selected;
    focusedDay = focused;
    notifyListeners();
  }

  void onFormatChanged(CalendarFormat format) {
    calendarFormat = format;
    notifyListeners();
  }

  void setDayTemplate(DateTime day, Template template) {
    final date = DateTime(day.year, day.month, day.day);
    final schedule = _schedules.putIfAbsent(date, () => DaySchedule(date));
    schedule.template = template;
    _logger.log('Template "${template.name}" applied to $date');
    notifyListeners();
  }

  List<ScheduleEvent> getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _schedules[date]?.events ?? [];
  }

  void addEvent(DateTime day, ScheduleEvent event) {
    final date = DateTime(day.year, day.month, day.day);
    final schedule = _schedules.putIfAbsent(date, () => DaySchedule(date));
    schedule.events.add(event);
    _logger.log('Scheduled ${event.song} on $date at ${event.time.hour}:${event.time.minute.toString().padLeft(2,'0')}');
    notifyListeners();
  }
}
