import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'providers/scheduler_provider.dart';

class RemoteControl {
  HttpServer? _server;

  Future<void> start({int port = 4040}) async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server!.listen(_handleRequest);
  }

  void _handleRequest(HttpRequest request) async {
    final provider = Provider.of<SchedulerProvider>(navigatorKey.currentContext!, listen: false);
    if (request.method == 'POST' && request.uri.path == '/volume') {
      final body = await utf8.decoder.bind(request).join();
      provider.log('Volume change: $body');
      request.response.write('OK');
    } else {
      request.response.statusCode = HttpStatus.notFound;
    }
    await request.response.close();
  }
}


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
