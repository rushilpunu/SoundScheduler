import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'models/template.dart';
import 'models/schedule.dart';
import 'providers/scheduler_provider.dart';
import 'remote_control.dart';

void main() {
  runApp(const SoundSchedulerApp());
  // Start remote control server
  RemoteControl().start();
}

class SoundSchedulerApp extends StatelessWidget {
  const SoundSchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SchedulerProvider(),
      child: MaterialApp(
        title: 'Sound Scheduler',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulerProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Scheduler'),
      ),
      body: Row(
        children: [
          NavigationRail(
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.calendar_today), label: Text('Schedule')),
              NavigationRailDestination(
                  icon: Icon(Icons.library_music), label: Text('Templates')),
              NavigationRailDestination(
                  icon: Icon(Icons.list), label: Text('Logs')),
            ],
            selectedIndex: provider.selectedIndex,
            onDestinationSelected: provider.setSelectedIndex,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: provider.selectedIndex,
              children: const [
                ScheduleView(),
                TemplateView(),
                LogView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulerProvider>(context);
    return Column(
      children: [
        TableCalendar(
          focusedDay: provider.focusedDay,
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          calendarFormat: provider.calendarFormat,
          selectedDayPredicate: (day) =>
              isSameDay(provider.selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            provider.onDaySelected(selectedDay, focusedDay);
          },
          onFormatChanged: provider.onFormatChanged,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: provider.getEventsForDay(provider.selectedDay).length,
            itemBuilder: (context, index) {
              final event =
                  provider.getEventsForDay(provider.selectedDay)[index];
              return ListTile(
                title: Text(event.song),
                subtitle: Text(event.time.format(context)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TemplateView extends StatelessWidget {
  const TemplateView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulerProvider>(context);
    return ListView(
      children: [
        for (final template in provider.templates)
          ListTile(
            title: Text(template.name),
            onTap: () => provider.setDayTemplate(
                provider.selectedDay, template),
          ),
      ],
    );
  }
}

class LogView extends StatelessWidget {
  const LogView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulerProvider>(context);
    return ListView(
      children: provider.logs
          .map((log) => ListTile(title: Text(log)))
          .toList(),
    );
  }
}
