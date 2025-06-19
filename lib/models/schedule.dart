import 'package:flutter/material.dart';
import 'template.dart';

class ScheduleEvent {
  final String song;
  final TimeOfDay time;
  ScheduleEvent(this.song, this.time);
}

class DaySchedule {
  final DateTime day;
  Template? template;
  final List<ScheduleEvent> events = [];

  DaySchedule(this.day, {this.template});
}
