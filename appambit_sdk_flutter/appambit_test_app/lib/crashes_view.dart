
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:appambit_sdk_flutter_example/utils/uuid_app.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';
import 'package:flutter/material.dart';

class CrashesView extends StatefulWidget {
  const CrashesView({super.key});
  @override
  State<CrashesView> createState() => _CrashesViewState();
}

class _CrashesViewState extends State<CrashesView> {
  final TextEditingController _userIdCtrl = TextEditingController(text: UuidApp.generateUuidV4());
  final TextEditingController _emailCtrl = TextEditingController(text: "test@gmail.com");
  final TextEditingController _customLogCtrl = TextEditingController( text: 'Test Log Message');
  var granted = false;

  @override
  void initState() {
    super.initState();
    _syncNotificationStatus();
  }

  Future<void> _syncNotificationStatus() async {
    final enabled = await PushNotificationsSdk.isNotificationsEnabled();
    if (!mounted) return;
    setState(() => granted = enabled);
  }

  Future<void> _showInfo(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Info'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications() async {
    try {
      granted = !granted;
      PushNotificationsSdk.requestNotificationPermission();
      await PushNotificationsSdk.setNotificationsEnabled(granted);

      final enabled = await PushNotificationsSdk.isNotificationsEnabled();

      setState(() {
        granted = enabled;
      });

      final msg = enabled
          ? 'Push notifications enabled'
          : 'Push notifications disabled';

      await _showInfo(msg);
    } catch (e) {
      await _showInfo('Failed to update notification settings');
    }
  }

  Future<void> _didCrashInLastSession() async {
    final didCrash = await AppAmbitSdk.didCrashInLastSession();
    final msg = didCrash
        ? 'Application crashed in the last session'
        : 'Application did not crash in the last session';
    await _showInfo(msg);
  }

  Future<void> _changeUserId() async {
    final id = _userIdCtrl.text.trim();
    if (id.isEmpty) return;
    await AppAmbitSdk.setUserId(id);    
    await _showInfo("User ID changed");
  }

  Future<void> _changeUserEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    await AppAmbitSdk.setEmail(email);
    await _showInfo("Email changed");
  }

  Future<void> _onTestErrorLogClicked() async {
    final msg = _customLogCtrl.text.trim();
    await AppAmbitSdk.logError(message: msg.isEmpty ? 'Test Log Message' : msg);
    await _showInfo("LogError sent");
  }

  Future<void> _onTestLog() async {
    await AppAmbitSdk.logError(message: 'Test Log Error', properties: <String, String>{'user_id': '1'});
    await _showInfo("LogError sent");
  }

  Future<void> _sendTestError() async {
    try {
      throw Exception('Test exception for logError');
    } catch (e, st) {
      await AppAmbitSdk.logError(
        exception: e,
        stackTrace: st,
        properties: <String, String>{'user_id': '1'}
      );
      await _showInfo("LogError sent");
    }
  }

  Future<void> _onSendTestLogWithClassFQN() async {
    await AppAmbitSdk.logError(
      message: 'Test log with classFQN',
      properties: <String, String>{'from': 'flutter'},
      classFqn: runtimeType.toString()
    );
    await _showInfo("LogError sent");
  }

  void _throwNewCrash() {
    Future.microtask(() {
      final list = <int>[];
      // ignore: unnecessary_statements
      list[10];
    });
  }

  Future<void> _generateTestCrash() => AppAmbitSdk.generateTestCrash();

  Widget _blueButton(String label, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  Widget _outlinedField({
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        autocorrect: false,
        textCapitalization: TextCapitalization.none,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _disabledBlock(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 96, 120, 141),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(text, style: const TextStyle(color: Color(0xFFF2F2F7))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _blueButton(
              granted ? "Disable Push Notifications" : "Enable Push Notifications",
              _toggleNotifications,
            ),
            const SizedBox(height: 8),

            _blueButton('Did the app crash during your last session?', _didCrashInLastSession),
            const SizedBox(height: 8),

            _outlinedField(hint: 'User Id', controller: _userIdCtrl),
            _blueButton('Change user id', _changeUserId),

            _outlinedField(
              hint: 'User email',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            _blueButton('Change user email', _changeUserEmail),

            _outlinedField(
              hint: 'Test Log Message',
              controller: _customLogCtrl,
              keyboardType: TextInputType.text,
            ),
            _blueButton('Send Custom LogError', _onTestErrorLogClicked),

            _blueButton('Send Default LogError', _onTestLog),
            _blueButton('Send Exception LogError', _sendTestError),
            _blueButton('Send ClassInfo LogError', _onSendTestLogWithClassFQN),
            
            _blueButton('Throw new Crash', _throwNewCrash),
            _blueButton('Generate Test Crash', () => _generateTestCrash()),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
