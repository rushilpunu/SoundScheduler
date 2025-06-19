# Sound Scheduler

A Windows desktop Flutter application for scheduling sound playback with calendar visualization, template management, remote control and logging.

## Features

- **Calendar view** to manage scheduled sounds.
- **Template system** for quickly applying sets of events to a day.
- **Remote control API** via HTTP to adjust volume and apply templates.
- **Sound logger** storing every played sound with timestamp and volume.

## Running

This project targets Flutter on Windows. Ensure you have Flutter installed and run:

```bash
flutter pub get
flutter run -d windows
```

The remote control server listens on `localhost:8080` and accepts:

- `POST /volume` with a numeric body to set master volume.
- `POST /template` with template name to apply it to the current schedule.
- `GET  /log` to view the sound log.

