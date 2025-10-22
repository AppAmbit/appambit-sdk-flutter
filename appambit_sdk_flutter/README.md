# AppAmbit: Getting Started with Flutter

This guide walks you through setting up the AppAmbit Flutter SDK in your application, focusing on AppAmbit Analytics and Crash Reporting.

## 1. Prerequisites

Before getting started, ensure you meet the following requirements:

- Flutter SDK >=3.3.0
- Dart SDK >=3.9.0
- **Android SDK with:**
    - Android 5.0+
    - compileSdkVersion 34
    - targetSdkVersion 34
    - minSdkVersion 21
- **iOS SDK with:**
    - Xcode 15+ (for iOS)
    - macOS 13+
- You are not using another SDK for crash reporting.

### Supported Platforms

- Flutter for iOS
- Flutter for Android

## 2. Creating Your App in the AppAmbit Portal

1. Visit [AppAmbit.com](http://appambit.com/).
2. Sign in or create an account. Navigate to "Apps" and click on "New App".
3. Provide a name for your app.
4. Select the appropriate release type and target OS.
5. Click "Create" to generate your app.
6. Retrieve the App Key from the app details page.
7. Use this App Key as a parameter when calling `AppambitSdk.start(appKey: '<YOUR-APPKEY>');` in your project.

## Adding the AppAmbit SDK to Your App

### [Pub.dev](pending)

Add the package to your Flutter project:

```bash
flutter pub add appambit_sdk_flutter
```

---

## Initializing the SDK

To begin using AppAmbit, you need to explicitly enable the services you wish to use. No services are activated by default.

### Import the Namespace

Add the required import directive to your file:

```dart
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
```

### Initialize AppAmbit

Call `AppambitSdk.start(appKey: '<YOUR-APPKEY>');` during application initialization:

```dart
AppambitSdk.start(appKey: '<YOUR-APPKEY>');
```

Here's an example of how to configure it within your `main.dart` class:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppambitSdk.start(appKey: '<YOUR-APPKEY>');

  runApp(const MyApp());
}
```

This code automatically generates a session, the session management is automatic.

#### Android Requirements

Add the following permissions in your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS and macOS (coming soon) Requirements

For iOS, add the required URL exceptions in your `Info.plist` file:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>appambit.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSThirdPartyExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## Crashes

### Generate a Test Crash

To simplify SDK testing, AppAmbit Crashes provides an API for generating a test crash.

Dart

```dart
AppambitSdk.generateTestCrash()
```

### Handled Errors

AppAmbit also supports tracking non-fatal errors by logging handled exceptions:

Dart
```dart
try {
    throw Exception('Test');
} catch (e, st) {
    await AppambitSdk.logError(
    exception: e,
    stackTrace: st,
    );
}
```

Besides, an application can attach properties to a controlled error report to provide more context. Pass the properties as a map of key-value pairs (strings only) as shown in the following example.


Dart
```dart
try {
    throw Exception('Test with Properties');
} catch (e, st) {
    await AppambitSdk.logError(
    exception: e,
    stackTrace: st,
    properties: <String, String>{'user_id': '1'}
    );
}
```

Additionally, you can log custom error messages for better visibility during unexpected situations:

Dart
```dart
try {
    ...
} catch (e, st) {
    final msg = "Error Exception";
    await AppambitSdk.logError(message: msg);
}
```

Even log with message and properties and use it to get details about errors

Dart
```dart
try {
    ...
} catch (e, st) {
    final msg = "Error Exception";
    await AppambitSdk.logError(
        message: msg,
        properties: <String, String>{'user_id': '1'}
    );
}
```

Details about the last crash

If the app has previously crashed, the function will return a boolean

Dart
```dart
await AppambitSdk.didCrashInLastSession();
```

AppAmbit will automatically generate a crash log every time your app crashes. The log is first written to the device's storage and when the user starts the app again, the crash report will be sent to AppAmbit. Collecting crashes works for both development, beta and production apps, i.e. those submitted through App Store Connect or Google Play Console. Crash logs contain valuable information for you to help fix the crash.


## Analytics


**AppAmbit.Analytics** helps you understand user behavior and customer engagement to improve your app. The SDK automatically captures session count and device properties like model, OS version, etc. You can define your own custom events to measure things that matter to you. All the information captured is available in the AppAmbit portal for you to analyze the data.

**Custom Events**
You can track your own custom events with custom properties  to understand the interaction between your users and the app. Once you've started the SDK, use the  `trackEvent()`  method to track your events with properties.
```dart
await AppambitSdk.trackEvent('ButtonClicked', <String, String>{'Count': '41'});
```
Properties for events are entirely optional – if you just want to track an event, use this sample instead:
```dart
await AppambitSdk.trackEvent("Order Placed", {});
```

## Offline Behavior

If the device is offline, the SDK will store sesssions, events, logs, and crashes locally. Once internet connectivity is restored, the SDK will automatically send the stored sesssions, events, logs, and crashes in batches.

## Network Connectivity Handling

- If the device transitions from offline to online, any pending requests are retried immediately.

## License

MIT License

Copyright (c) 2025 AppAmbit

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.