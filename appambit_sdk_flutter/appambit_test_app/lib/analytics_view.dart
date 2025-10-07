import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:flutter/material.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});
  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
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

  String _repeatToLength(String seed, int len) {
    final b = StringBuffer();
    while (b.length < len) {
      b.write(seed);
    }
    final s = b.toString();
    return s.substring(0, len);
  }

  Future<void> _onTokenRefreshTest() async {
    final futures = List.generate(5, (i) {
      return AppambitSdk.logError(
        message: 'Sending logs 5 after invalid token',
        properties: <String, String>{'user_id': '1'},
        classFqn: 'AnalyticsView',
        fileName: 'analytics_view.dart',
        lineNumber: 10 + i,
      );
    });
    await Future.wait(futures);

    for (var i = 1; i <= 5; i++) {
      await AppambitSdk.trackEvent(
        'Sending event 5 after invalid token',
        <String, String>{'Test Token': '5 events sent'},
      );
    }

    await _showInfo('5 events and 5 errors sent');
  }

  Future<void> _startSession() async => AppambitSdk.startSession();
  Future<void> _endSession() async => AppambitSdk.endSession();
  Future<void> _invalidateToken() async => AppambitSdk.clearToken();
  Future<void> _sendButtonClickedEvent() async =>
      AppambitSdk.trackEvent('ButtonClicked', <String, String>{'Count': '41'});
  Future<void> _sendDefaultEvent() async => AppambitSdk.generateTestEvent();

  Future<void> _onClickedTestLimitsEvent() async {
    final c300 = _repeatToLength('1234567890', 300);
    final c300b = _repeatToLength('1234567890', 301);
    final props = <String, String>{c300: c300, c300b: c300b};
    await AppambitSdk.trackEvent(c300, props);
  }

  Future<void> _onClickedTestMaxPropertiesEven() async {
    final props = <String, String>{
      '01': '01',
      '02': '02',
      '03': '03',
      '04': '04',
      '05': '05',
      '06': '06',
      '07': '07',
      '08': '08',
      '09': '09',
      '10': '10',
      '11': '11',
      '12': '12',
      '13': '13',
      '14': '14',
      '15': '15',
      '16': '16',
      '17': '17',
      '18': '18',
      '19': '19',
      '20': '20',
      '21': '21',
      '22': '22',
      '23': '23',
      '24': '24',
      '25': '25',
    };
    await AppambitSdk.trackEvent('TestMaxProperties', props);
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _blueButton('Invalidate Token', _invalidateToken),
            _blueButton('Token refresh test', _onTokenRefreshTest),
            _blueButton('Start Session', _startSession),
            _blueButton('End Session', _endSession),

            _blueButton("Send 'Button Clicked' Event w/ property", _sendButtonClickedEvent),
            _blueButton('Send Default Event w/ property', _sendDefaultEvent),
            _blueButton('Send Max-300-Length Event', _onClickedTestLimitsEvent),
            _blueButton('Send Max-20-Properties Event', _onClickedTestMaxPropertiesEven),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
