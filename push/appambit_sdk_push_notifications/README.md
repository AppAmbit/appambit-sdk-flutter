# AppAmbit Push Notifications SDK

**Seamlessly integrate push notifications with your AppAmbit analytics.**

This SDK is an extension of the core AppAmbit SDK, providing a simple and powerful way to handle Firebase Cloud Messaging (FCM) notifications on both Android and iOS.

---

## Contents

* [Features](#features)
* [Requirements](#requirements)
* [Install](#install)
* [Quickstart](#quickstart)
* [Usage](#usage)
* [Native Implementation Setup](#native-implementation-setup)
  * [Android Setup](#android-setup)
  * [iOS Setup](#ios-setup)
  * [iOS Notification Service Extension (Rich Notifications)](#ios-notification-service-extension-rich-notifications)

---

## Features

* **Zero-Config iOS**: No native code changes required — the SDK wires itself up automatically via method swizzling.
* **Simple Setup**: Integrates in minutes.
* **Enable/Disable Notifications**: Easily manage user preferences at both the business and FCM level.
* **Robust Event Listeners**: Separate callbacks for Foreground, Background, and Opened (tapped) notifications on both platforms.
* **Android Background Support**: Handle background notifications even when the app is completely closed via headless Flutter engine.
* **Automatic Field Handling**: Automatically uses standard FCM payload fields like `color`, `icon`, `channel_id`, `click_action`, and rich images.
* **Rich Media Support**: Full iOS Notification Service Extension support for rich payloads, badges, and media attachments.
* **Permission Helpers**: Utilities to request and check the `POST_NOTIFICATIONS` permission.

---

## Requirements

* **AppAmbit Core SDK**: Requires the core `appambit_sdk_flutter` to be installed and configured.
* **Firebase Project**: A configured Firebase project with:
  - `google-services.json` downloaded and placed in `android/app/`
  - `GoogleService-Info.plist` downloaded and added to `ios/Runner/` in Xcode
* **Android**: API level 24 (Nougat) or newer, Firebase Messaging dependency
* **iOS**: iOS 13.0 or newer, **Push Notifications** capability enabled on the Runner target

---

## Install

### 1. Add the packages

```bash
flutter pub add appambit_sdk_flutter
flutter pub add appambit_sdk_push_notifications
```

### 2. Android Configuration

Add Firebase and Google Services plugin to your Gradle files.

**`android/app/build.gradle`** (Groovy)
```groovy
apply plugin: "com.google.gms.google-services"

dependencies {
    implementation platform('com.google.firebase:firebase-bom:33.1.2')
    implementation 'com.google.firebase:firebase-messaging:23.4.0'
}
```

**`android/build.gradle`** (Groovy)
```groovy
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.3.15")
    }
}
```

<details>
<summary>Kotlin DSL</summary>

**`android/app/build.gradle.kts`**
```kotlin
apply(plugin = "com.google.gms.google-services")

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-messaging:23.4.0")
}
```

**`android/build.gradle.kts`**
```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.3.15")
    }
}
```
</details>

Ensure `minSdk = 24` in `android/app/build.gradle` (the plugin requires it).

### 3. iOS Configuration

After installing the package, install pods:

```bash
cd ios && pod install
```

The AppAmbit iOS pods resolve automatically as dependencies of the plugin.

---

## Quickstart

In your `main.dart`, initialize both SDKs **in order**:

```dart
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';

void main() {
  // 1. Start core SDK first
  AppAmbitSdk.start(appKey: '<YOUR-APPKEY>');
  
  // 2. Start push SDK
  PushNotificationsSdk.start();
  
  // 3. Request permission (shows system dialog)
  PushNotificationsSdk.requestNotificationPermission();
  
  runApp(const MyApp());
}
```

That's it! Your app is ready to receive push notifications.

---

## Usage

### Event Listeners

All listeners are **singleton-like**: calling `setForegroundListener()` again replaces the previous one. Each listener returns a cleanup function you can call on unmount (e.g. in `dispose()`).

#### Foreground Listener
Fires when a notification arrives while the app is active and open.

```dart
@override
void initState() {
  super.initState();
  _unsubscribeForeground = PushNotificationsSdk.setForegroundListener((payload) {
    print('Foreground: ${payload.title}');
  });
}

@override
void dispose() {
  _unsubscribeForeground?.call();
  super.dispose();
}
```

#### Opened Listener
Fires when the user taps a notification, regardless of app state (foreground, background, or killed).

```dart
@override
void initState() {
  super.initState();
  _unsubscribeOpened = PushNotificationsSdk.setOpenedListener((payload) {
    print('Notification tapped: ${payload.title}');
  });
}

@override
void dispose() {
  _unsubscribeOpened?.call();
  super.dispose();
}
```

#### Background Listener (Android only)
Fires when a notification arrives **while the app is backgrounded or killed**. On iOS, there is no Dart callback — customize the Notification Service Extension instead (see [iOS NSE](#ios-notification-service-extension-rich-notifications)).

The handler runs in a **headless Flutter engine** with no access to your app's state or UI.

```dart
@override
void initState() {
  super.initState();
  _unsubscribeBackground = PushNotificationsSdk.Android.setBackgroundListener((payload) async {
    print('Background: ${payload.title}');
    // Handler runs in separate isolate — cannot access app state
    // The SDK automatically waits for this Future to complete before signaling the OS
  });
}

@override
void dispose() {
  _unsubscribeBackground?.call();
  super.dispose();
}
```

### Permission Helpers

```dart
// Show system permission dialog (fire-and-forget)
PushNotificationsSdk.requestNotificationPermission();

// Show dialog and get result
final granted = await PushNotificationsSdk.requestNotificationPermissionWithResult();
if (granted) {
  print('User granted permission');
} else {
  print('User denied permission');
}

// Check permission without showing dialog
final hasPermission = await PushNotificationsSdk.hasNotificationPermission();

// Optional: Pass a callback to requestNotificationPermission()
PushNotificationsSdk.requestNotificationPermission(
  callback: (granted) {
    if (granted) {
      print('Permission granted!');
    } else {
      print('Permission denied.');
    }
  },
);
```

### Notification Payload

Every listener receives a `PushNotificationData`:

```dart
class PushNotificationData {
  final String? title;              // Notification title
  final String? body;               // Notification body
  final String? imageUrl;           // URL of attached image
  final Map<String, String>? data;  // Custom key-value pairs
  final AndroidPushData? android;   // Android-specific fields (null on iOS)
  final IosPushData? ios;           // iOS-specific fields (null on Android)
}

class AndroidPushData {
  final String? color;              // e.g. #FF5722
  final String? smallIconName;      // drawable resource name
  final String? ticker;
  final bool? sticky;               // Non-dismissable
  final String? visibility;         // Lock screen visibility
  final String? channelId;          // Notification channel
  final String? tag;                // For grouping/replacing
  final String? sound;
  final String? clickAction;
}

class IosPushData {
  final int? badge;                 // Icon badge number
  final String? sound;
  final String? category;           // For action buttons
  final String? threadId;           // For grouping
}
```

### Enable / Disable Notifications

```dart
// Opt out (still respects OS permission, but SDK-level toggle is off)
PushNotificationsSdk.setNotificationsEnabled(false);

// Opt back in
PushNotificationsSdk.setNotificationsEnabled(true);

// Check current state
final isEnabled = await PushNotificationsSdk.isNotificationsEnabled();

// Check OS permission independently
final hasOsPermission = await PushNotificationsSdk.hasNotificationPermission();
```

> **Note**: Notifications only display when **both** OS permission is granted **and** the SDK toggle is enabled.

---

## Native Implementation Setup

### Android Setup

The SDK's `AndroidManifest.xml` automatically merges all required permissions and services — no manifest edits needed.

#### For Background Notifications (Killed App)

Register a background handler at startup in `main()`:

```dart
@pragma('vm:entry-point')
void _backgroundNotificationHandler(PushNotificationData payload) {
  print('Background notification (killed): ${payload.title}');
  // This runs in a headless Flutter engine — no access to app state
}

void main() {
  AppAmbitSdk.start(appKey: '<YOUR-APPKEY>');
  PushNotificationsSdk.start();
  
  // Register for background notifications BEFORE runApp
  PushNotificationsSdk.Android.setBackgroundHandler(_backgroundNotificationHandler);
  
  runApp(const MyApp());
}
```

**Important**: The handler must be:
- **Top-level or static** — not a class method or closure
- **Annotated with `@pragma('vm:entry-point')`** — prevents tree-shaking by the Dart AOT compiler
- **Async-safe** — can use `async`/`await` and `Future`s
- **Isolated** — cannot access state, UI, or global variables from your app

#### Offline Behavior

When the device is offline and you call `setNotificationsEnabled(false)`:
1. The state is saved to local `SharedPreferences`
2. The next time the device comes online, the SDK syncs the state to the backend
3. This ensures FCM token state matches the backend, even if sync was delayed

---

### iOS Setup

#### 1. Enable Push Notifications Capability

In Xcode:
1. Open `ios/Runner.xcworkspace` (not `.xcodeproj`)
2. Select the **Runner** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability** and add **Push Notifications**

#### 2. Configure the entitlements file

Push Notifications require the `aps-environment` entitlement in `ios/Runner/Runner.entitlements`. If you added the capability via Xcode UI in the previous step, this is handled automatically. If you manage the file manually (e.g. via CI or version control), two things must be in place:

**Step 1 — Wire the entitlements file to Xcode**

In Xcode, select the **Runner** target → **Build Settings** → search for **Code Signing Entitlements** → set the value to `Runner/Runner.entitlements` for **both** Debug and Release configurations.

**Step 2 — Add the `aps-environment` key to the entitlements file**

In your Flutter project, open the file at `ios/Runner/Runner.entitlements` (you can open it from the Finder, or in Xcode by expanding **Runner → Runner** in the Project Navigator and clicking `Runner.entitlements`). It is an XML plist — add the `aps-environment` key inside the `<dict>`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>   <!-- use "production" for App Store / TestFlight builds -->
</dict>
</plist>
```

If the file does not exist yet, create it at that path with the content above.

> Without `aps-environment`, APNs rejects device registration and no push token is ever delivered to the app.

#### 2. Install Pods

```bash
flutter pub get
cd ios && pod install
```

No manual pod entries or native changes needed — the SDK auto-registers via method swizzling.

---

### iOS Notification Service Extension (Rich Notifications)

To display **rich notifications with images** and handle custom mutations, create a Notification Service Extension.

#### 1. Add NSE Target in Xcode

1. Open `ios/Runner.xcworkspace`
2. **File > New > Target**
3. Select **Notification Service Extension**
4. Name it `NotificationService`, click **Finish**
5. When prompted, activate the scheme

#### 2. Add Pod to Podfile

Outside the main `target 'Runner'` block:

```ruby
target 'NotificationService' do
  pod 'AppAmbitPushNotificationsExtension', '~> 1.1.0'
end
```

Then run:
```bash
cd ios && pod install
```

#### 3. Implement NotificationService.swift

Replace `NotificationService.swift` with:

```swift
import UserNotifications
import AppAmbitPushNotificationsExtension

class NotificationService: AppAmbitNotificationService {
  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    // Base class handles image download and attachment automatically
    super.didReceive(request, withContentHandler: contentHandler)
  }

  override func serviceExtensionTimeWillExpire() {
    // Called ~5 seconds before timeout — deliver with best-effort content
    super.serviceExtensionTimeWillExpire()
  }
}
```

**Important NSE Constraints**:
- Runs in a **separate process** — cannot access your app's state or UI
- **~30 second time limit** — requests must complete quickly
- **~24 MB memory limit** — cannot load large assets
- No Flutter engine — pure native Swift

If you need to customize notification content (e.g., modify title), override `didReceive` **before** calling `super`:

```swift
override func didReceive(
  _ request: UNNotificationRequest,
  withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
) {
  guard let bestAttempt = request.content.mutableCopy() as? UNMutableNotificationContent else {
    contentHandler(request.content)
    return
  }
  
  // Custom logic here
  bestAttempt.title = "[Modified] \(bestAttempt.title)"
  
  // Let base class handle image + send
  let newRequest = UNNotificationRequest(
    identifier: request.identifier,
    content: bestAttempt,
    trigger: request.trigger
  )
  super.didReceive(newRequest, withContentHandler: contentHandler)
}
```

#### Template A — Minimal (No Custom Code)

Use this when you only need the SDK's automatic handling: parse the payload, download the image URL, and attach it to the notification.

```swift
import UserNotifications
import AppAmbitPushNotificationsExtension

class NotificationService: AppAmbitNotificationService {}
```

---

#### Template B — Custom Mutations

Use this when you need to mutate notification content before it's displayed (modify title, body, category, badge, thread ID, attachments, etc.).

```swift
import UserNotifications
import AppAmbitPushNotificationsExtension

class NotificationService: AppAmbitNotificationService {
  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
      contentHandler(request.content)
      return
    }

    let userInfo = bestAttemptContent.userInfo
    let aps = userInfo["aps"] as? [String: Any]

    // Example customizations — keep only what you need
    bestAttemptContent.title += " [Custom]"

    if let category = aps?["category"] as? String {
      bestAttemptContent.categoryIdentifier = category
    }
    if let threadId = aps?["thread-id"] as? String {
      bestAttemptContent.threadIdentifier = threadId
    }

    let newRequest = UNNotificationRequest(
      identifier: request.identifier,
      content: bestAttemptContent,
      trigger: request.trigger
    )
    super.didReceive(newRequest, withContentHandler: contentHandler)
  }

  override func serviceExtensionTimeWillExpire() {
    super.serviceExtensionTimeWillExpire()
  }
}
```

---

The override runs inside the NSE process and must complete within the ~30 s / ~24 MB limits Apple imposes on Notification Service Extensions. Always call `super.didReceive` to ensure the base class handles image download and attachment.
