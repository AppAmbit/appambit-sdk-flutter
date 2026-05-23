# AppAmbit Push Notifications SDK

**Seamlessly integrate push notifications with your AppAmbit analytics.**

This SDK is an extension of the core AppAmbit Flutter SDK, providing a simple and powerful way to handle push notifications on both **Android** (via Firebase Cloud Messaging) and **iOS** (via APNs).

---

## Contents

* [Features](#features)
* [Requirements](#requirements)
* [Install](#install)
* [Quickstart](#quickstart)
* [Usage](#usage)
* [Native Setup](#native-setup)
  * [Android Setup](#android-setup)
  * [iOS Setup](#ios-setup)
  * [iOS Notification Service Extension](#ios-notification-service-extension-rich-notifications)
* [Customization](#customization)

---

## Features

* **Simple Setup**: Integrates in minutes on both Android and iOS.
* **Enable/Disable Notifications**: Easily manage user preferences at the SDK level, independent of the OS permission.
* **Robust Event Listeners**: Separate callbacks for foreground, background (Android), and opened (tapped) notifications on both platforms.
* **Automatic Field Handling**: Automatically uses standard fields from the FCM payload (Android) and APNs `aps` dictionary (iOS) — including `color`, `icon`, `channel_id`, `click_action`, badges, and rich images.
* **Rich Media Support**: Full integration with iOS Notification Service Extensions for image attachments and payload mutations.
* **Permission Helper**: Simple utilities to request and check notification permission on Android 13+ and iOS.
* **Advanced Customization**: Powerful hooks to extend or replace notification handling on both platforms.

---

## Requirements

* **AppAmbit Core SDK**: This SDK is an extension and requires the core `appambit_sdk_flutter` to be installed and configured.
* **Android**: A configured Firebase project with `google-services.json` in your app module. Android API level 24 (Nougat) or newer (`minSdk = 24`).
* **iOS**: An APNs-enabled app identifier, the `Push Notifications` capability on your Runner target, and a Notification Service Extension target for rich notifications. iOS 12.0 or newer.

---

## Install

### 1. Add the packages

This package is an extension of the core SDK, so install **both** from your project directory:

```bash
flutter pub add appambit_sdk_flutter
flutter pub add appambit_sdk_push_notifications
```

### 2. Android setup

See [Android Setup](#android-setup) under Native Setup.

### 3. iOS setup

See [iOS Setup](#ios-setup) under Native Setup.

---

## Quickstart

1. **Initialize the Core SDK**: In your `main.dart`, initialize the core AppAmbit SDK with your App Key.

    ```dart
    AppAmbitSdk.start(appKey: '<YOUR-APPKEY>');
    ```

2. **Initialize the Push SDK**: Immediately after, start the Push Notifications SDK.

    ```dart
    PushNotificationsSdk.start();
    ```

3. **Request Permissions**: Request the OS notification permission. On Android 13+ this shows the `POST_NOTIFICATIONS` system prompt; on iOS it shows the APNs authorization dialog.

    ```dart
    PushNotificationsSdk.requestNotificationPermission();
    ```

**That's it!** Your app is now ready to receive and display push notifications on both platforms.

---

## Usage

### Enabling and Disabling Notifications

The SDK-level toggle starts enabled. To manage user preferences, use `setNotificationsEnabled`. Note that notifications are only shown when **both** the SDK toggle is on and the OS permission is granted (see [System Permission vs. SDK Toggle](#system-permission-vs-sdk-toggle)).

```dart
// Disable all future notifications
PushNotificationsSdk.setNotificationsEnabled(false);

// Re-enable them
PushNotificationsSdk.setNotificationsEnabled(true);
```

This method updates the opt-out status on the AppAmbit dashboard and prevents the device from showing push notifications. You can check the current setting at any time:

```dart
var isEnabled = await PushNotificationsSdk.isNotificationsEnabled();
```

### System Permission vs. SDK Toggle

`hasNotificationPermission()` and `isNotificationsEnabled()` report **two independent** states — check the one you actually need:

| Method | Platform | Returns |
|---|---|---|
| `hasNotificationPermission()` | Android + iOS | Whether the **OS** currently allows this app to show notifications (iOS authorization status / Android 13+ `POST_NOTIFICATIONS` grant). The user controls this from system settings or the permission prompt. |
| `isNotificationsEnabled()` | Android + iOS | The **SDK-level** toggle set via `setNotificationsEnabled(bool)` and synced to your AppAmbit dashboard. Independent of the OS permission. |

```dart
final hasOsPermission = await PushNotificationsSdk.hasNotificationPermission();
final sdkEnabled      = await PushNotificationsSdk.isNotificationsEnabled();

// A device shows notifications only when BOTH are true.
```

### Permission Listener (Optional)

To know if the user granted or denied the notification permission, pass a callback.

```dart
PushNotificationsSdk.requestNotificationPermission(
  callback: (granted) {
    if (granted) {
      print("Permission granted!");
    } else {
      print("Permission denied.");
    }
  },
);
```

### Receiving Notifications

Register cross-platform listeners to react to notifications.

#### Foreground Listener (Android + iOS)

Fires when a notification arrives while the app is open in the foreground.

```dart
PushNotificationsSdk.setForegroundListener((data) {
  print('Foreground push: ${data.title}');
});
```

#### Opened Listener (Android + iOS)

Fires when the user taps a notification, regardless of the app's initial state (foreground, background, or killed).

```dart
PushNotificationsSdk.setOpenedListener((data) {
  print('User tapped: ${data.title}');
});
```

#### Background Handler (Android only)

For work that must run when a push arrives with the app in background or killed. Register a top-level Dart function annotated with `@pragma('vm:entry-point')`. It runs in a dedicated background isolate (no UI, no shared state with the main isolate) and survives app kill.

```dart
@pragma('vm:entry-point')
void myBackgroundHandler(PushNotificationData data) {
  // analytics, local DB writes, etc.
}

await PushNotificationsSdk.Android.setBackgroundHandler(myBackgroundHandler);
```

The handler **must** be a top-level or static function. Closures and instance methods cannot be looked up by `PluginUtilities.getCallbackFromHandle`.

> **iOS**: There is no Dart background callback on iOS. The Notification Service Extension (NSE) runs in a separate process with no Flutter engine. iOS background customization is done by subclassing `AppAmbitNotificationService` in your NSE Swift target — see [iOS Notification Service Extension](#ios-notification-service-extension-rich-notifications).

### Notification Data Model

Every listener receives a `PushNotificationData` object. The foreground and opened listeners fire on **both platforms**; the background handler is **Android-only**.

| Field | Type | Platform | Notes |
|---|---|---|---|
| `title` | `String?` | Android + iOS | Notification title. |
| `body` | `String?` | Android + iOS | Notification body text. |
| `imageUrl` | `String?` | Android + iOS | URL of the attached image, if any. |
| `data` | `Map<String, String>?` | Android + iOS | Your custom payload key-value pairs. The raw iOS `aps` dictionary is **not** included here. |
| `android` | `AndroidPushData?` | Android only | `null` on iOS. Contains Android-specific extras. |
| `ios` | `IosPushData?` | iOS only | `null` on Android. Contains iOS-specific extras parsed from `aps`. |

The `android` and `ios` objects carry the platform-specific extras the SDK already parsed for you:

**`AndroidPushData`** (Android only):

- `color` (`String?`) — accent color applied to the notification (e.g. `#FF5722`).
- `smallIconName` (`String?`) — drawable resource name used for the status-bar icon.
- `channelId` (`String?`) — notification channel the message was posted to.
- `priority` (`String?`) — notification priority.
- `sound` (`String?`) — sound played for the notification.
- `clickAction` (`String?`) — intent action triggered when the user taps it.
- `ticker` (`String?`) — accessibility ticker text.
- `visibility` (`String?`) — lock-screen visibility.
- `tag` (`String?`) — tag used to update/replace an existing notification.
- `sticky` (`bool?`) — whether the notification is ongoing (non-dismissable).

**`IosPushData`** (iOS only) — parsed from the APNs `aps` dictionary:

- `subtitle` (`String?`) — secondary line shown under the title (`aps.alert.subtitle`).
- `badge` (`int?`) — number shown on the app icon badge (`aps.badge`).
- `sound` (`String?`) — sound played for the notification (`aps.sound`).
- `category` (`String?`) — category identifier for actionable notifications (`aps.category`).
- `threadId` (`String?`) — id used to group related notifications (`aps.thread-id`).

```dart
PushNotificationsSdk.setOpenedListener((data) {
  final badge   = data.ios?.badge;            // iOS only
  final channel = data.android?.channelId;    // Android only
  final custom  = data.data?['your_key'];     // Android + iOS
});
```

---

## Native Setup

### Android Setup

#### a. Add `google-services.json`

Download the file from your Firebase project console and place it in your app module:

```
android/app/google-services.json
```

#### b. Apply the Google Services Gradle plugin

This plugin processes `google-services.json` at build time. Add it to your Gradle files (pick the syntax matching your project).

**Kotlin DSL**

`android/app/build.gradle.kts`
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

`android/build.gradle.kts`
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

**Groovy**

`android/app/build.gradle`
```groovy
plugins {
    id "com.google.gms.google-services"
}
```

`android/build.gradle`
```groovy
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.google.gms:google-services:4.3.15"
    }
}
```

#### c. Set the minimum SDK to 24

The plugin requires `minSdk = 24`. If your app is on a lower value, raise it in `android/app/build.gradle.kts`:

```kotlin
defaultConfig {
    minSdk = 24
}
```

The `POST_NOTIFICATIONS` runtime permission (Android 13+) is declared by the SDK and merged into your manifest automatically — you don't need to add it. Call `requestNotificationPermission()` at runtime to prompt the user.

---

### iOS Setup

#### a. Enable the Push Notifications capability

In Xcode, open `ios/Runner.xcworkspace`, select the **Runner** target, go to **Signing & Capabilities**, and add the **Push Notifications** capability.

#### b. Install the AppAmbit iOS pods

The AppAmbit iOS pods (`AppAmbitSdk`, `AppAmbitPushNotifications`) are published to CocoaPods and declared as dependencies of the plugin, so they resolve automatically:

```bash
flutter pub get
cd ios && pod install
```

No manual pod entries are needed for the main `Runner` target.

---

### iOS Notification Service Extension (Rich Notifications)

To display images and to mutate notification content before it is shown, you must add a Notification Service Extension (NSE) target. Apple requires the NSE to live in its own target — Flutter cannot do this for you.

#### 1. Add the target in Xcode

1. Open `ios/Runner.xcworkspace`.
2. Go to **File → New → Target… → Notification Service Extension**.
3. Name it `NotificationService`. Activate the scheme if Xcode asks.

#### 2. Add the extension pod

The base class `AppAmbitNotificationService` ships in a **separate pod**, `AppAmbitPushNotificationsExtension`. Add a target block for it in your `ios/Podfile`, then run `pod install` again:

```ruby
target 'NotificationService' do
  use_frameworks!
  pod 'AppAmbitPushNotificationsExtension', '1.0.0'
end
```

#### 3. Implement the extension

Replace the contents of the generated `NotificationService.swift` with one of the templates below.

The NSE has hard runtime limits: **~30 s of execution and ~24 MB of memory**. Keep code inside it short and synchronous where possible.

---

##### Template A — Minimal (no custom code)

Use this when you only need what the SDK provides automatically: parse the AppAmbit payload, download the `image` URL, and attach it to the banner.

```swift
import AppAmbitPushNotificationsExtension

class NotificationService: AppAmbitNotificationService {}
```

---

##### Template B — Mutating content in `didReceive`

Use this when you need to mutate the notification before it is shown (title, body, badge, category, thread identifier, attachments, etc.). Mutate in `didReceive`, build a fresh request, and forward to `super.didReceive` so the base class still downloads any attached image and delivers the notification.

```swift
import UserNotifications
import AppAmbitPushNotificationsExtension

class NotificationService: AppAmbitNotificationService {

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }

        let userInfo = bestAttemptContent.userInfo
        let aps = userInfo["aps"] as? [String: Any]

        // Examples — keep only what you need.
        bestAttemptContent.title += " Custom"

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
}
```

The override runs inside the NSE process and must complete within the ~30 s / ~24 MB limits Apple imposes on Notification Service Extensions.

---

## Customization

### Automatic Customization

The SDK automatically configures the notification by reading standard fields from your push payload. **For most use cases, you won't need to write any custom code.** The fields the SDK reads differ by platform.

**Android — FCM `notification` object:**

- **`title`**: The notification's title.
- **`body`**: The notification's main text.
- **`icon`**: The name of a drawable resource for the small icon.
- **`color`**: The notification's accent color (e.g., `#FF5722`).
- **`click_action`**: An intent filter name to be triggered when the notification is tapped.
- **`channel_id`**: The ID of the notification channel to use.
- **`image`**: A URL to an image to be displayed in the notification.
- **`notification_priority`**: The integer priority of the notification (e.g., `1` for `PRIORITY_HIGH`).

**iOS — APNs payload (`aps`):**

- **`aps.alert.title` / `aps.alert.subtitle` / `aps.alert.body`**: Title, subtitle, and body shown on the banner.
- **`aps.sound`**: Sound played for the notification.
- **`aps.badge`**: Number shown on the app icon badge.
- **`aps.category`**: Category identifier used for action buttons.
- **`aps.thread-id`**: Groups related notifications together.
- **`image`** (top-level key): URL of an image the Notification Service Extension downloads and attaches. Requires the NSE and `mutable-content: 1` — see [iOS Notification Service Extension](#ios-notification-service-extension-rich-notifications).

**`data` object (Android + iOS):**

The `data` object is a free-form container for any custom key-value pairs you wish to send. Its sole purpose is to pass custom data to your application. In Dart you read it from the `data` map on the `PushNotificationData` delivered to your listeners on both platforms:

```dart
PushNotificationsSdk.setOpenedListener((notification) {
  final value = notification.data?['your_key'];
  // ...your custom logic
});
```

### Advanced Customization

For platform-specific customization beyond what the automatic field handling covers, the entry points are:

**iOS** — override `didReceive` in your `AppAmbitNotificationService` subclass — see [Template B](#template-b--mutating-content-in-didreceive).

**Android** — provide your own notification-service extension. There are two ways, depending on whether you still want the Dart background handler:

**Recommended — subclass `AppambitFlutterPushExtension`.** This keeps the Dart bridge (your `setBackgroundHandler` callback) working. Override the `Context` overload, do your native work, and call `super` so the payload still reaches Dart:

```kotlin
package com.example.myapp

import android.content.Context
import com.appambit.sdk.models.AppAmbitNotification
import com.example.appambit_sdk_push_notifications.AppambitFlutterPushExtension

class MyPushExtension : AppambitFlutterPushExtension() {
    override fun onNotificationBackground(
        context: Context,
        notification: AppAmbitNotification,
    ) {
        // Native logic — e.g. read notification.title / notification.data
        super.onNotificationBackground(context, notification) // keep Dart dispatch
    }
}
```

**Full control — implement `IAppAmbitNotificationServiceExtension` directly.** Use this only if you don't need the Dart background handler; implementing the interface from scratch replaces the bridge. The interface (`com.appambit.sdk.IAppAmbitNotificationServiceExtension`) exposes `onNotificationForeground` and `onNotificationBackground`, each with a single-arg `(AppAmbitNotification)` form and a `(Context, AppAmbitNotification)` form — use the latter when you need a `Context`.

Either way, point the SDK at your class by overriding the meta-data entry in your **app's** `AndroidManifest.xml`. The plugin already declares this key internally pointing to its own bridge — adding it in your app's manifest overrides that default:

```xml
<application>
  <meta-data
      android:name="com.appambit.sdk.NotificationServiceExtension"
      android:value="com.example.myapp.MyPushExtension"/>
</application>
```

`android:name` is a fixed key defined in `com.appambit.sdk.MessagingService` — the SDK reads it at runtime via reflection to instantiate your extension class. Do not change this value. `android:value` is the fully-qualified name of **your** class (replace `com.example.myapp.MyPushExtension` with your actual package and class name).

The callbacks fire even when the app is killed, with full access to `Context` and the parsed `AppAmbitNotification` — `title`, `body`, `imageUrl`, `data`, plus Android extras such as `color`, `channelId`, `priority`, and `sound`.
