class Logger {
  final List<String> logs = [];

  void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    logs.add('[$timestamp] $message');
  }
}
