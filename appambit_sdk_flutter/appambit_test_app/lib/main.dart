import 'package:appambit_sdk_flutter_example/analytics_view.dart';
import 'package:appambit_sdk_flutter_example/crashes_view.dart';
import 'package:appambit_sdk_flutter_example/remote_config_view.dart';
import 'package:appambit_sdk_flutter_example/cms_view.dart';
import 'package:appambit_sdk_flutter_example/second_screen.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';
import 'package:flutter/material.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Uncomment the line for automatic session management
  //AppAmbitSdk.enableManualSession();
  AppAmbitSdk.enableConfig();
  AppAmbitSdk.start(appKey: '<YOUR-APPKEY>');
  PushNotificationsSdk.start();

  PushNotificationsSdk.setForegroundListener((data) {
    debugPrint('[Push] Foreground: ${data.title}');
  }); 

  PushNotificationsSdk.setOpenedListener((data) {
    // Defer until the next frame so the Navigator is mounted, especially on
    // cold-start when the tap launches the5app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'second_screen'),
          builder: (context) => const SecondScreen(),
        ),
      );
    });
  });

  // Android-only: runs in a background isolate when a push arrives with the
  // app in background or killed. The handler must be a top-level function
  // marked with @pragma('vm:entry-point'); see [pushBackgroundHandler] below.
  await PushNotificationsSdk.Android.setBackgroundHandler(pushBackgroundHandler);



  runApp(const MyApp());
}

@pragma('vm:entry-point')
void pushBackgroundHandler(PushNotificationData data) {
  // No UI access here — runs in a dedicated background isolate.
  debugPrint('[Push] Background (Android): ${data.title} - ${data.body}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
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

  List<Widget> get _pages => [
    const CrashesView(),
    const AnalyticsView(),
    RemoteConfigView(isActive: _index == 2),
    const CmsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getTitle())),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber),
            label: 'Crashes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_remote),
            label: 'Remote Config',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'CMS'),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_index) {
      case 0:
        return 'Crashes';
      case 1:
        return 'Analytics';
      case 2:
        return 'Remote Config';
      case 3:
        return 'CMS Native';
      default:
        return 'AppAmbit SDK';
    }
  }
}