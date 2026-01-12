import 'package:appambit_sdk_flutter_example/analytics_view.dart';
import 'package:appambit_sdk_flutter_example/crashes_view.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';
import 'package:flutter/material.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Uncomment the line for automatic session management
  //AppAmbitSdk.enableManualSession();
  AppAmbitSdk.start(appKey: '<YOUR-APPKEY>');
  PushNotificationsSdk.start();
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [AppAmbitSdk()],
      title: 'AppAmbit SDK Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MainBottomNavPage(),
    );
  }
}

class MainBottomNavPage extends StatefulWidget {
  const MainBottomNavPage({super.key});
  @override
  State<MainBottomNavPage> createState() => _MainBottomNavPageState();
}

class _MainBottomNavPageState extends State<MainBottomNavPage> {
  int _index = 0;

  final _pages = const [
    CrashesView(),
    AnalyticsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_index == 0 ? 'Crashes' : 'Analytics')),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber), label: 'Crashes'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
        ],
      ),
    );
  }
}

