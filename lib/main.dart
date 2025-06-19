import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(SoundSchedulerApp());
}

class SoundSchedulerApp extends StatefulWidget {
  @override
  State<SoundSchedulerApp> createState() => _SoundSchedulerAppState();
}

class _SoundSchedulerAppState extends State<SoundSchedulerApp> {
  final ScheduleManager scheduleManager = ScheduleManager();
  late final HttpServer _server;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);
    _server = await shelf_io.serve(handler, 'localhost', 8080);
    print('Remote control server running on localhost:${_server.port}');
  }

  Future<Response> _router(Request request) async {
    if (request.url.path == 'volume') {
      final volume = double.tryParse(await request.readAsString()) ?? 1.0;
      scheduleManager.player.setVolume(volume);
      return Response.ok('volume set');
    } else if (request.url.path == 'template') {
      final name = await request.readAsString();
      scheduleManager.applyTemplate(name);
      return Response.ok('template applied');
    } else if (request.url.path == 'log') {
      return Response.ok(await scheduleManager.readLog());
    }
    return Response.notFound('not found');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sound Scheduler',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SchedulerHome(scheduleManager: scheduleManager),
    );
  }

  @override
  void dispose() {
    _server.close();
    super.dispose();
  }
}

class SchedulerHome extends StatefulWidget {
  final ScheduleManager scheduleManager;
  const SchedulerHome({Key? key, required this.scheduleManager}) : super(key: key);

  @override
  State<SchedulerHome> createState() => _SchedulerHomeState();
}

class _SchedulerHomeState extends State<SchedulerHome> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sound Scheduler')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: widget.scheduleManager.eventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
          Expanded(
            child: ListView(
              children: widget.scheduleManager
                  .eventsForDay(_selectedDay ?? DateTime.now())
                  .map((e) => ListTile(
                        title: Text(e.trackPath),
                        subtitle: Text(DateFormat.Hm().format(e.time)),
                      ))
                  .toList(),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _openAddDialog(context),
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Sound'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, decoration: const InputDecoration(labelText: 'Track path')),
              TextButton(
                onPressed: () async {
                  final time = await showTimePicker(context: context, initialTime: selectedTime);
                  if (time != null) {
                    selectedTime = time;
                  }
                },
                child: const Text('Pick time'),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final now = _selectedDay ?? DateTime.now();
                final dt = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
                widget.scheduleManager.addEvent(SoundEvent(time: dt, trackPath: controller.text));
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );
  }
}

class SoundEvent {
  final DateTime time;
  final String trackPath;
  final double volume;
  SoundEvent({required this.time, required this.trackPath, this.volume = 1.0});
}

class Template {
  final String name;
  final List<SoundEvent> events;
  Template({required this.name, required this.events});
}

class ScheduleManager {
  final Map<DateTime, List<SoundEvent>> _events = {};
  final Map<String, Template> _templates = {};
  final AudioPlayer player = AudioPlayer();
  late final File _logFile;

  ScheduleManager() {
    _init();
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/sound_log.txt');
    if (!await _logFile.exists()) {
      await _logFile.create(recursive: true);
    }
    Timer.periodic(const Duration(minutes: 1), (_) => _checkSchedule());
  }

  List<SoundEvent> eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void addEvent(SoundEvent event) {
    final key = DateTime(event.time.year, event.time.month, event.time.day);
    _events.putIfAbsent(key, () => []);
    _events[key]!.add(event);
    _events[key]!.sort((a, b) => a.time.compareTo(b.time));
  }

  void addTemplate(Template template) {
    _templates[template.name] = template;
  }

  void applyTemplate(String name) {
    final template = _templates[name];
    if (template == null) return;
    for (var event in template.events) {
      addEvent(event);
    }
  }

  Future<void> _checkSchedule() async {
    final now = DateTime.now();
    final events = eventsForDay(now);
    for (var event in events) {
      if (event.time.hour == now.hour && event.time.minute == now.minute) {
        await player.play(DeviceFileSource(event.trackPath), volume: event.volume);
        await _log(event);
      }
    }
  }

  Future<void> _log(SoundEvent event) async {
    final log =
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())} - ${event.trackPath} at volume ${event.volume}\n';
    await _logFile.writeAsString(log, mode: FileMode.append);
  }

  Future<String> readLog() async => _logFile.readAsString();
}
