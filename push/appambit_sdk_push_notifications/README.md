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
* **Android**: A configured Firebase project and a `google-services.json` file in your application module. Android API level 21 (Lollipop) or newer.
* **iOS**: an APNs-enabled app identifier, the `Push Notifications` capability on your Runner target, and a Notification Service Extension target (see [iOS Setup](#ios-setup)). iOS 12.0 or newer.

---

## Install

To install the library from Pub.dev, run the following commands in your project directory:

```bash
flutter pub add appambit_sdk_flutter
```
```bash
flutter pub add appambit_sdk_push_notifications
```

Add the following dependencies to your app's `build.gradle` file. Your app is still responsible for providing the Firebase Bill of Materials (BOM) to ensure version compatibility.

**Kotlin DSL**
**`android/app/build.gradle`**
```groovy
plugins {
    // Google services (FCM)
    id("com.google.gms.google-services")
}
```
**`android/build.gradle`**
```groovy
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
**`android/app/build.gradle`**
```groovy
plugins {
    // Google services (FCM)
    id "com.google.gms.google-services"
}
```
**`android/build.gradle`**
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

Also, ensure you have the Google Services plugin configured in your project.

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

3.  **Request Permissions**: In your main activity, request the required notification permission.

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

While the iOS pods are being published, point the example app's `Podfile`
at a local checkout of `appambit-sdk-ios`:

```ruby
target 'Runner' do
  use_frameworks!

  pod 'AppAmbitSdk',
      :path => '../../../../appambit-sdk-ios/AppAmbitSdk'
  pod 'AppAmbitPushNotifications',
      :path => '../../../../appambit-sdk-ios/Push/AppAmbitPushNotifications'

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

Adjust the relative path to match your layout. Once the pods are published
this block is removed.

### 2. Notification Service Extension (NSE)

To display images and to mutate notification content on iOS you must add a
Notification Service Extension target to your app. Apple requires the NSE to
live in its own target — Flutter cannot do this for you.

**Add the target in Xcode:**

1. Open `ios/Runner.xcworkspace`.
2. `File → New → Target… → Notification Service Extension`.
3. Name it `NotificationService`. Activate the scheme if Xcode asks.
4. Add `AppAmbitPushNotifications` to the new target's **Frameworks and Libraries** (same pod as above; reference it via the Podfile so it is linked to the extension as well).
5. Replace the contents of the generated `NotificationService.swift` with one of the templates below.

The NSE has hard runtime limits: **~30 s of execution and ~24 MB of memory**.
Keep code inside it short and synchronous where possible.

---

#### Template A — Minimal (no custom code)

Use this template when you only need what the SDK already does for free:
parse the AppAmbit payload, download the `image` URL, and attach it to the
banner. No callbacks, no mutation.

```swift
import AppAmbitPushNotifications

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
import AppAmbitPushNotifications

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
        bestAttemptContent.title += " ✨"

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

The `data` object is a free-form container for any custom key-value pairs you wish to send (e.g., `{"your_key": "your_value", "another_key": 123}`). Its sole purpose is to pass custom data to your application, which you can then access using the `NotificationCustomizer` to implement any advanced logic you require.

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
