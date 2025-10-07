import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppambitSdk.start(appKey: '<YOUR-APIKEY>');
  } on PlatformException catch (e) {
    debugPrint('Failed to start AppAmbit core: ${e.message}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'idle';
  final String demoUserId = '42';

  void _setStatus(String s) => setState(() => _status = s);

  Future<void> _setUserId() async {
    _setStatus('setUserId...');
    try {
      await AppambitSdk.setUserId(demoUserId);
      _setStatus('userId set');
    } catch (e) {
      _setStatus('error setUserId: $e');
    }
  }

  Future<void> _trackEvent() async {
    _setStatus('trackEvent...');
    try {
      await AppambitSdk.trackEvent('button_pressed', {'button': 'trackEvent_example'});
      _setStatus('event tracked');
    } catch (e) {
      _setStatus('error trackEvent: $e');
    }
  }

  Future<void> _generateTestEvent() async {
    _setStatus('generateTestEvent...');
    try {
      await AppambitSdk.generateTestEvent();
      _setStatus('generateTestEvent sent');
    } catch (e) {
      _setStatus('error generateTestEvent: $e');
    }
  }

  Future<void> _sendCaughtException() async {
    _setStatus('sending caught exception...');
    try {
      try {
        throw Exception('Demo exception from Dart');
      } catch (e, st) {
        await AppambitSdk.logError(
          exception: e,
          stackTrace: st,
          properties: {'screen': 'home', 'flow': 'example'},
          classFqn: 'com.example.HomePage',
          fileName: 'main.dart',
          lineNumber: 123,
        );
        _setStatus('logError sent (exception + stack)');
      }
    } catch (e) {
      _setStatus('error sending exception: $e');
    }
  }

  Future<void> _sendMessageOnly() async {
    _setStatus('sending message-only error...');
    try {
      await AppambitSdk.logError(

      );
      _setStatus('logError sent (message only)');
    } catch (e) {
      _setStatus('error message-only: $e');
    }
  }

  Future<void> _logErrorMessage() async {
    _setStatus('logErrorMessage...');
    try {
      throw Exception('Demo exception from Dart');
    } catch (e, st) {
      await AppambitSdk.logError(
        exception: e,
        stackTrace: st,
        properties: {'screen': 'home', 'flow': 'example'},
        classFqn: 'com.example.HomePage',
        fileName: 'main.dart',
        lineNumber: 123,
      );
    }
  }

  Future<void> _generateTestCrash() async {
    _setStatus('generateTestCrash...');
    try {
      await AppambitSdk.generateTestCrash();
      _setStatus('generateTestCrash invoked');
    } catch (e) {
      _setStatus('error generateTestCrash: $e');
    }
  }

  Future<void> _didCrashInLastSession() async {
    _setStatus('checking last session crash...');
    try {
      final didCrash = await AppambitSdk.didCrashInLastSession();
      _setStatus('didCrashInLastSession: $didCrash');
    } catch (e) {
      _setStatus('error checking crash: $e');
    }
  }

  Future<void> _enableManualSession() async {
    _setStatus('enableManualSession...');
    try {
      await AppambitSdk.enableManualSession();
      _setStatus('manual session enabled');
    } catch (e) {
      _setStatus('error enableManualSession: $e');
    }
  }

  Future<void> _startSession() async {
    _setStatus('startSession...');
    try {
      await AppambitSdk.startSession();
      _setStatus('session started');
    } catch (e) {
      _setStatus('error startSession: $e');
    }
  }

  Future<void> _endSession() async {
    _setStatus('endSession...');
    try {
      await AppambitSdk.endSession();
      _setStatus('session ended');
    } catch (e) {
      _setStatus('error endSession: $e');
    }
  }

  Future<void> _clearToken() async {
    _setStatus('clearToken...');
    try {
      await AppambitSdk.clearToken();
      _setStatus('token cleared');
    } catch (e) {
      _setStatus('error clearToken: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AppAmbit SDK Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('Status: $_status'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _setUserId, child: const Text('setUserId')),
              ElevatedButton(onPressed: _trackEvent, child: const Text('trackEvent')),
              ElevatedButton(onPressed: _generateTestEvent, child: const Text('generateTestEvent')),
              ElevatedButton(onPressed: _sendCaughtException, child: const Text('logError')),
              ElevatedButton(onPressed: _sendMessageOnly, child: const Text('logError (message only)')),
              ElevatedButton(onPressed: _logErrorMessage, child: const Text('logErrorMessage (simple)')),
              ElevatedButton(onPressed: _generateTestCrash, child: const Text('generateTestCrash (will crash)')),
              const Divider(),
              ElevatedButton(onPressed: _didCrashInLastSession, child: const Text('didCrashInLastSession')),
              ElevatedButton(onPressed: _enableManualSession, child: const Text('enableManualSession')),
              ElevatedButton(onPressed: _startSession, child: const Text('startSession')),
              ElevatedButton(onPressed: _endSession, child: const Text('endSession')),
              ElevatedButton(onPressed: _clearToken, child: const Text('clearToken')),
              TextButton(
                onPressed: () => throw Exception("Throw Test Exception"),
                child: const Text("Throw Test Exception"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
