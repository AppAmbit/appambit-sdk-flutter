# AppAmbit Push Notifications SDK

**Seamlessly integrate push notifications with your AppAmbit analytics.**

This SDK is an extension of the core AppAmbit Flutter SDK, providing a simple and powerful way to handle Firebase Cloud Messaging (FCM) notifications.

---

## Contents

* [Features](#features)
* [Requirements](#requirements)
* [Install](#install)
* [Quickstart](#quickstart)
* [Usage](#usage)
* [iOS Setup](#ios-setup)
* [Customization](#customization)

---

## Features

* **Simple Setup**: Integrates in minutes.
* **Enable/Disable Notifications**: Easily manage user preferences at both the business and FCM level.
* **Automatic Field Handling**: Automatically uses standard fields from the FCM payload like `color`, `icon`, `channel_id`, and `click_action`.
* **Smart Icon Selection**: Automatically uses your app's icon, with a safe fallback.
* **Advanced Customization**: Provides a powerful hook to modify notifications for advanced use cases.
* **Permission Helper**: Includes a simple utility to request the `POST_NOTIFICATIONS` permission.

---

## Requirements

* **AppAmbit Core SDK**: This SDK is an extension and requires the core `appambit_sdk_flutter` to be installed and configured.
* **Android**: A configured Firebase project and a `google-services.json` file in your application module. Android API level 24 (Nougat) or newer (`minSdk = 24`).
* **iOS**: an APNs-enabled app identifier, the `Push Notifications` capability on your Runner target, and a Notification Service Extension target (see [iOS Setup](#ios-setup)). iOS 12.0 or newer.

---

## Install

### 1. Add the packages

This package is an extension of the core SDK, so install **both** from your
project directory:

```bash
flutter pub add appambit_sdk_flutter
flutter pub add appambit_sdk_push_notifications
```

You do **not** need to add `firebase-messaging` yourself — the plugin already
bundles it. The only Firebase wiring your app provides is the
`google-services.json` file and the Google Services Gradle plugin (below).

### 2. Android setup

**a. Add `google-services.json`**

Download the file from your Firebase project's console and place it in your
app module:

```
android/app/google-services.json
```

**b. Apply the Google Services Gradle plugin**

This plugin processes `google-services.json` at build time. Add it to your
Gradle files (pick the syntax matching your project).

**Kotlin DSL**

`android/app/build.gradle.kts`
```kotlin
plugins {
    // Google services (FCM)
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
        // Google services (FCM)
        classpath("com.google.gms:google-services:4.3.15")
    }
}
```

**Groovy**

`android/app/build.gradle`
```groovy
plugins {
    // Google services (FCM)
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
        // Google services (FCM)
        classpath "com.google.gms:google-services:4.3.15"
    }
}
```

**c. Set the minimum SDK to 24**

The plugin requires `minSdk = 24`. If your app is on a lower value, raise it
in `android/app/build.gradle.kts`:

```kotlin
defaultConfig {
    minSdk = 24
}
```

The `POST_NOTIFICATIONS` runtime permission (Android 13+) is declared by the
SDK and merged into your manifest automatically — you don't need to add it.
Call [`requestNotificationPermission`](#permission-listener-optional) at
runtime to prompt the user.

### 3. iOS setup

iOS needs the **Push Notifications** capability on your Runner target and a
Notification Service Extension. See [iOS Setup](#ios-setup).

---

## Quickstart

1.  **Initialize the Core SDK**: In your `main.dart`, initialize the core AppAmbit SDK with your App Key.

    ```dart
    AppAmbitSdk.start(appKey: '<YOUR-APPKEY>');
    ```

2.  **Initialize the Push SDK**: Immediately after, start the Push Notifications SDK.

    ```dart
    PushNotificationsSdk.start();
    ```

3.  **Request Permissions**: Request the OS notification permission. This shows the system prompt on Android 13+ and on iOS.

    ```dart
    PushNotificationsSdk.requestNotificationPermission();
    ```

**That's it!** Your app is now ready to receive and display push notifications.

---

## Usage

### Enabling and Disabling Notifications

By default, notifications are enabled when you first call `start()`. To manage user preferences afterward, use `setNotificationsEnabled`.

```dart
// To disable all future notifications
PushNotificationsSdk.setNotificationsEnabled(false);

// To re-enable them
PushNotificationsSdk.setNotificationsEnabled(true);
```

This method updates the opt-out status on the AppAmbit dashboard and stops the device from receiving FCM messages. You can check the current setting at any time:

```dart
var isEnabled = await PushNotificationsSdk.isNotificationsEnabled();
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

Register cross-platform listeners to react to notifications. Both fire on
**Android and iOS**.

```dart
PushNotificationsSdk.setForegroundListener((data) {
  print('Foreground push: ${data.title}');
});

PushNotificationsSdk.setOpenedListener((data) {
  print('User tapped: ${data.title}');
});
```

### Background Handlers

For work that must run when a push arrives with the app in background or
killed, the two platforms require different mechanisms because iOS runs
notification-time code in a Notification Service Extension (NSE) — a separate
process that cannot host a Flutter engine.

**Android** — register a top-level Dart function annotated with
`@pragma('vm:entry-point')`. It runs in a dedicated background isolate
(no UI, no shared state with the main isolate) and survives app kill:

```dart
@pragma('vm:entry-point')
void myBackgroundHandler(PushNotificationData data) {
  // analytics, local DB writes, etc.
}

await PushNotificationsSdk.Android.setBackgroundHandler(myBackgroundHandler);
```

The handler **must** be a top-level or static function. Closures and instance
methods cannot be looked up by `PluginUtilities.getCallbackFromHandle`.

**iOS** — subclass `AppAmbitNotificationService` in your NSE Swift target
(see [iOS Setup](#ios-setup)). The base class downloads attached images
automatically and gives you a `didReceive` hook to mutate content.

---

## iOS Setup

### 1. Install the AppAmbit iOS pods

For the main `Runner` target you don't need to add any pods by hand. The
AppAmbit iOS pods (`AppAmbitSdk`, `AppAmbitPushNotifications`) are published
to CocoaPods and declared as dependencies of the plugin, so they resolve
automatically:

```bash
flutter pub get
cd ios && pod install
```

Make sure the **Push Notifications** capability is enabled on the `Runner`
target in Xcode (`Signing & Capabilities → + Capability → Push Notifications`).

### 2. Notification Service Extension (NSE)

To display images and to mutate notification content on iOS you must add a
Notification Service Extension target to your app. Apple requires the NSE to
live in its own target — Flutter cannot do this for you.

**Add the target in Xcode:**

1. Open `ios/Runner.xcworkspace`.
2. `File → New → Target… → Notification Service Extension`.
3. Name it `NotificationService`. Activate the scheme if Xcode asks.
4. Link the NSE against the AppAmbit extension pod. The base class
   `AppAmbitNotificationService` ships in a **separate pod**,
   `AppAmbitPushNotificationsExtension`. Add a target block for it in your
   `ios/Podfile`, then run `pod install` again:

    ```ruby
    target 'NotificationService' do
      use_frameworks!
      pod 'AppAmbitPushNotificationsExtension', '1.0.0'
    end
    ```

5. Replace the contents of the generated `NotificationService.swift` with one of the templates below.

The NSE has hard runtime limits: **~30 s of execution and ~24 MB of memory**.
Keep code inside it short and synchronous where possible.

---

#### Template A — Minimal (no custom code)

Use this template when you only need what the SDK already does for free:
parse the AppAmbit payload, download the `image` URL, and attach it to the
banner. No callbacks, no mutation.

```swift
import AppAmbitPushNotificationsExtension

/// Minimal NSE. Subclassing `AppAmbitNotificationService` is enough — the
/// SDK handles payload parsing and image attachment automatically.
class NotificationService: AppAmbitNotificationService {}
```

---

#### Template B — Mutating content in `didReceive`

Use this template when you need to mutate the notification before it is shown
(title, body, badge, category, thread identifier, attachments, etc.). Mutate
in `didReceive`, build a fresh request, and forward to `super.didReceive` so
the base class still downloads any attached image and delivers the
notification.

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
        let dataPayload = userInfo["data"] as? [AnyHashable: Any] ?? userInfo

        // Examples — keep only what you need.
        bestAttemptContent.title += " Custom"

        if let category = dataPayload["category_type"] as? String {
            bestAttemptContent.categoryIdentifier = category
        }
        if let threadId = dataPayload["chat_id"] as? String {
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

The override runs inside the NSE process and must complete within the
~30 s / ~24 MB limits Apple imposes on Notification Service Extensions.

---

## Customization

The SDK is designed to be highly customizable, automatically adapting to the data you send in your FCM payload, while also offering a powerful hook for advanced modifications.

### Automatic Customization

The SDK automatically configures the notification by reading standard fields from your FCM message. **For most use cases, you won't need to write any custom code.**

**`notification` object:**

The SDK uses the standard keys from the FCM `notification` object.

- **`title`**: The notification's title.
- **`body`**: The notification's main text.
- **`icon`**: The name of a drawable resource for the small icon.
- **`color`**: The notification's accent color (e.g., `#FF5722`).
- **`click_action`**: An intent filter name to be triggered when the notification is tapped.
- **`channel_id`**: The ID of the notification channel to use.
- **`image`**: A URL to an image to be displayed in the notification.
- **`notification_priority`**: The integer priority of the notification (e.g., `1` for `PRIORITY_HIGH`).

**`data` object:**

The `data` object is a free-form container for any custom key-value pairs you wish to send (e.g., `{"your_key": "your_value", "another_key": 123}`). Its sole purpose is to pass custom data to your application. In Dart you read it from the `data` map on the `PushNotificationData` delivered to your [foreground/opened listeners](#receiving-notifications) (or the Android background handler):

```dart
PushNotificationsSdk.setOpenedListener((notification) {
  final value = notification.data?['your_key'];
  // ...your custom logic
});
```

### Advanced Customization

For platform-specific customization beyond what the automatic field handling
covers, the entry points are:

- **iOS**: override `didReceive` in your `AppAmbitNotificationService`
  subclass — see [Template B](#template-b--mutating-content-in-didreceive).
- **Android**: implement your own `IAppAmbitNotificationServiceExtension` in
  Kotlin/Java and override the plugin's default by declaring your class in
  your app's `AndroidManifest.xml`:

    ```xml
    <application>
      <meta-data
          android:name="com.appambit.sdk.NotificationServiceExtension"
          android:value="com.example.myapp.MyPushExtension"/>
    </application>
    ```

    The class your `meta-data` points at receives `onNotificationForeground`
    and `onNotificationBackground` callbacks from the AppAmbit Android SDK
    even when the app is killed, with full access to `Context` and the
    parsed `AppAmbitNotification` payload.
