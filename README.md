<picture>
  <source media="(prefers-color-scheme: light)" srcset="https://assets.appambit.com/logo-light.svg">
  <source media="(prefers-color-scheme: dark)" srcset="https://assets.appambit.com/logo-dark.svg">
  <img alt="AppAmbit logo" src="https://assets.appambit.com/logo-dark.svg" width="280">
</picture>

# AppAmbit Flutter SDK

**The App Command Center.**
Everything your app needs after you build it, in one connected platform instead of stitching together separate tools.

[![Discord](https://img.shields.io/discord/1418426396836888617?label=Discord&logo=discord&color=5865F2)](https://discord.gg/nJyetYue2s)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![pub package](https://img.shields.io/pub/v/appambit_sdk_flutter.svg)](https://pub.dev/packages/appambit_sdk_flutter)
[![platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-brightgreen.svg)](https://pub.dev/packages/appambit_sdk_flutter)

---

## Quick start

1. Sign up free at [appambit.com](https://appambit.com), no credit card required
2. Create an app in the dashboard and grab your app key
3. Install the SDK ([see below](#install))
4. Initialize it at app launch:

**Dart**

```dart
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppAmbitSdk.start(appKey: '<YOUR-APPKEY>');

  runApp(const MyApp());
}
```

That's it. Crashes, sessions, and analytics start flowing immediately. Full setup guides live in the [docs](https://docs.appambit.com).

---

## What's inside

### 🚀 Ship
- **Build delivery**: push a build from GitHub, Bitbucket, Azure DevOps, or manually, then send it to team, testers, or clients by email or direct install, and track who installed it
- **Live updates**: ship changes without waiting on an app store review

### 📊 Monitor
- **Crash & error monitoring**: uncaught crashes and unhandled Dart errors are captured with full stack traces, then uploaded on the next launch, grouped with who's affected and email alerts on new issues
- **Error logging**: structured log messages with custom properties for quick diagnostics, sent even when the app does not crash
- **Session timeline & breadcrumbs**: automatic route navigation trail so you see exactly what led to a crash
- **Analytics & event tracking**: automatic session starts, stops, and durations plus structured events with custom properties, live and compared across versions

### 📈 Grow
- **Push notifications**: APNs and FCM through the optional `appambit_sdk_push_notifications` package, targeted by segment and scheduled from the dashboard
- **Remote config & feature flags**: typed keys (`getString`, `getBoolean`, `getLong`, `getDouble`) with version targeting, so you can flip features, run gradual rollouts, or hit the kill switch without a release
- **CMS**: define content types and entries in the dashboard, then read articles, FAQs, and promos with a fluent query builder that supports filters, full-text search, sorting, and pagination, decoded straight into your own Dart models

### 🗄️ Backend
- **App database**: a managed SQL database with a fluent query builder, batches, and transactions, straight from the SDK or the dashboard
- **Cloud code**: deploy JavaScript functions triggered by HTTP, data events, or manually, then invoke them from the app with typed results, cancellation, and request correlation. Every deploy is a version, so rollback is one click
- **AI agent (MCP)**: build your backend from a conversation with Claude or Cursor ([more below](#built-for-agentic-coding))

### 👥 Teams
- Workspaces, squads, roles and access, per-app reporting

---

## Built for agentic coding

Point Claude or Cursor at the AppAmbit MCP server and it can provision your entire backend from a conversation (content types, database schema, and cloud code functions) while writing the app code that calls them. Paired with a [sample app](#sample-apps) or a [starter app](#starter-apps), that means going from a prompt to a working app with a live backend in a single sitting.

Set it up from the AppAmbit dashboard under **Settings → AI Assistant**, where you create the personal access token and get the connection details for your assistant.

---

## Requirements

* Flutter 3.3.0 or newer
* Dart 3.9.2 or newer
* **Android**: Android 5.0 (API 21) or newer, `compileSdk` 34+
* **iOS**: iOS 12 or newer, Xcode 15 or newer on macOS 13 or newer

---

## Getting started

- [Install](#install)
  - [pub.dev](#pubdev)
  - [Android permissions](#android-permissions)
  - [Push setup](#choose-a-push-setup)
- [Track events](#track-events)
- [Logs](#logs)
- [Breadcrumbs](#breadcrumbs)
- [Remote config](#remote-config)
- [Release distribution](#release-distribution)
- [CMS](#cms)
- [Database](#database)
- [Cloud code](#cloud-code)

### Install

#### pub.dev

> Requires **v1.2.0 or newer**. Earlier versions do not include Cloud Code support.

```bash
flutter pub add appambit_sdk_flutter
```

Or add it to your `pubspec.yaml` directly:

```yaml
dependencies:
  flutter:
    sdk: flutter
  appambit_sdk_flutter: ^1.2.0
```

then run `flutter pub get`.

| Package | Add when | Import |
|---|---|---|
| `appambit_sdk_flutter` | Always | `package:appambit_sdk_flutter/appambit_sdk_flutter.dart` |
| `appambit_sdk_push_notifications` | *(optional, only if you use push)* | `package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart` |

#### Android permissions

Add these to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### Choose a push setup

Push notifications are delivered over FCM (Android) and APNs (iOS) and ship as a separate package:

```bash
flutter pub add appambit_sdk_push_notifications
```

Start it after the core SDK:

```dart
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';

await AppAmbitSdk.start(appKey: '<YOUR-APPKEY>');
await PushNotificationsSdk.start();
await PushNotificationsSdk.requestNotificationPermission();

PushNotificationsSdk.setForegroundListener((notification) {
  debugPrint('Foreground: ${notification.title}');
});
PushNotificationsSdk.setOpenedListener((notification) {
  debugPrint('Opened: ${notification.title}');
});
```

iOS needs no native code: the SDK wires itself up via swizzling. Android needs a `google-services.json` and the Google Services Gradle plugin. For background messages with the app fully closed, use `PushNotificationsAndroid`; for rich iOS notifications, add a Notification Service Extension.

See the [Push Notifications guide](push/appambit_sdk_push_notifications/README.md) for the complete setup, including Gradle configuration, iOS entitlements, and the Notification Service Extension.

---

### Usage

Everything below works once `AppAmbitSdk.start(appKey:)` has run. Session activity (starts, stops, and durations) is tracked automatically, and uncaught crashes plus unhandled Dart errors are captured and uploaded on the next launch with no extra code.

### Track events

Send structured events with custom properties.

```dart
await AppAmbitSdk.trackEvent('ButtonClicked', <String, String>{'Count': '41'});
```

Also available: `AppAmbitSdk.setUserId`, `setEmail`, `startSession`, `endSession`, and `enableManualSession` if you want to drive sessions yourself.

---

### Logs

Add structured log messages for debugging, sent even when the app does not crash.

```dart
try {
  throw Exception('Test with Properties');
} catch (e, st) {
  await AppAmbitSdk.logError(
    exception: e,
    stackTrace: st,
    properties: <String, String>{'user_id': '1'},
  );
}
```

`logError` also accepts a plain `message`, plus optional `classFqn`, `fileName`, and `lineNumber` if you want to override the inferred call site. `AppAmbitSdk.didCrashInLastSession()` tells you whether the previous run ended in a crash.

---

### Breadcrumbs

`AppAmbitSdk` is a `NavigatorObserver`, so route changes (push, pop, replace) are recorded for you once you register it:

```dart
MaterialApp(
  navigatorObservers: [AppAmbitSdk()],
  home: const HomePage(),
);
```

Name your routes (`RouteSettings(name: 'MyPage')`) so the dashboard timeline reads clearly. Without a name, the route appears under its default description.

---

### Remote config

Fetch and apply remote configuration values asynchronously using type-safe methods.

```dart
// Enable remote config
await AppAmbitSdk.enableConfig();
await AppAmbitSdk.start(appKey: '<YOUR-APPKEY>');

// Get remote config values with type-safe methods
final String? message = await AppAmbitSdk.getString('data');
final bool isFeatureEnabled = await AppAmbitSdk.getBoolean('banner');
final int discount = await AppAmbitSdk.getLong('discount');
final double maxUpload = await AppAmbitSdk.getDouble('max_upload');
```

---

### Release distribution

Ship a build to your team, testers, or clients without waiting on a store review. Connect GitHub, Bitbucket, or Azure DevOps so every pipeline run uploads its artifact. Send it out by email or a direct install link, and see who actually installed it.

This repo ships a pipeline for each one that builds and signs the app, ready to copy into your own:

| CI | Pipeline |
| --- | --- |
| GitHub Actions (Android) | [.github/workflows/build-apk.yml](.github/workflows/build-apk.yml) |
| GitHub Actions (iOS) | [.github/workflows/build-ipa.yml](.github/workflows/build-ipa.yml) |
| Bitbucket Pipelines | [bitbucket-pipelines.yml](bitbucket-pipelines.yml) |
| Azure DevOps (Android) | [azure-pipelines-android.yml](azure-pipelines-android.yml) |
| Azure DevOps (iOS) | [azure-pipelines-ios.yml](azure-pipelines-ios.yml) |

---

### CMS

Read content you publish from the dashboard (articles, FAQs, promos) without shipping a new build. `AppAmbitCms.content<T>` decodes entries straight into your own model through the `fromJson` you supply.

```dart
final posts = await AppAmbitCms.content<BlogPost>(
  'blog_extended',
  fromJson: BlogPost.fromJson,
)
    .equals('is_published', 'true')
    .orderByDescending('views_count')
    .getPerPage(20)
    .getList();
```

Also available: `search`, `notEquals`, `contains`, `startsWith`, `greaterThan(OrEqual)`, `lessThan(OrEqual)`, `inList`, `notInList`, `orderByAscending`, `getPage`.

---

### Database

Query, insert, update, and delete rows in your AppAmbit database with a fluent builder.

```dart
// Query rows
final tasks = await AppAmbitDb.from('tasks')
    .where('done', 0)
    .orderByDesc('id')
    .limit(10)
    .get();

// Insert a row
await AppAmbitDb.from('tasks').insert({'title': 'Buy milk', 'done': 0});

// Update requires at least one where()
await AppAmbitDb.from('tasks')
    .where('id', 1)
    .update({'done': 1});
```

Use `fromMapped<T>` to decode rows into your own type. Also available: `select`, `whereOp` (for `>`, `<`, `LIKE`, and the rest of the allowed operators), `whereIn`, `orderBy`, `offset`, `first`, `count`, `delete`, plus raw SQL through `AppAmbitDb.execute`, `batch`, and `batchInTransaction`.

---

### Cloud code

Invoke authenticated HTTP functions hosted by AppAmbit. Cloud Code uses the same consumer and Bearer token as the rest of the SDK, so no extra setup is needed beyond `AppAmbitSdk.start`. Configure an active Cloud Function with an enabled HTTP trigger and slug in the dashboard, then call it. Calls are request/response only and are not queued for offline upload.

```dart
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';

final request = CloudCode.call(
  'hello',
  method: CloudCodeHttpMethod.post,
  body: {'name': 'Ada'},
);

try {
  final response = await request.future;
  debugPrint('HTTP ${response.statusCode}: ${response.data}');
} on CloudCodeError catch (error) {
  debugPrint('${error.code}: ${error.message}');
}
```

Use `CloudCode.callTyped<T>` for a typed result. `call` returns a `CloudCodeRequest`, so you can cancel it before the response lands.

Cloud Code supports dynamic and typed JSON responses, request IDs, cancellation, reserved-header validation, and a native 60-second timeout. See the [Cloud Code mobile guide](https://docs.appambit.com/sdk-guides/cloud-code/) for function setup, HTTP triggers, errors, cancellation, and backend examples.

---

## Sample apps

This repo ships a manual-test app that exercises every public feature, one screen per capability:

| App | Path |
| --- | --- |
| `appambit_test_app` | [appambit_sdk_flutter/appambit_test_app](appambit_sdk_flutter/appambit_test_app) |
| Push notifications example | [push/appambit_sdk_push_notifications/example](push/appambit_sdk_push_notifications/example) |

Replace `<YOUR-APPKEY>` with a real app key before running them, and drop in your own `google-services.json` if you want push on Android.

---

## Starter apps

Skip the blank-project setup. Clone a starter with AppAmbit already wired in: auth, push notifications, analytics, and a CMS-driven feed that needs no rebuild to change content. Each one ships with ready-made content sets you can import directly into your AppAmbit dashboard, then customize to make the app your own.

| Starter | Repo |
| --- | --- |
| Flutter | [organization-app-starter-flutter](https://github.com/AppAmbit/organization-app-starter-flutter) |
| .NET MAUI | [organization-app-starter-maui](https://github.com/AppAmbit/organization-app-starter-maui) |
| React Native | [organization-app-starter-react-native](https://github.com/AppAmbit/organization-app-starter-react-native) |

---

## Other SDKs

Open-source, one per platform. Analytics, crashes, session timeline, CMS, database, and remote config all in the same package.

> One .NET SDK repo, three targets: MAUI, WPF/WinUI, and Avalonia each ship as separate packages from the same source.

| Platform | Repo | Package |
| --- | --- | --- |
| **Flutter** *(you are here)* | [appambit-sdk-flutter](https://github.com/AppAmbit/appambit-sdk-flutter) | [pub.dev](https://pub.dev/packages/appambit_sdk_flutter) |
| iOS | [appambit-sdk-ios](https://github.com/AppAmbit/appambit-sdk-ios) | [CocoaPods](https://cocoapods.org/pods/appambitsdk) · [Swift Package Manager](https://github.com/AppAmbit/appambit-sdk-ios) |
| Android | [appambit-sdk-android](https://github.com/AppAmbit/appambit-sdk-android) | [Maven Central](https://central.sonatype.com/artifact/com.appambit/appambit) |
| .NET MAUI | [appambit-sdk-dotnet](https://github.com/AppAmbit/appambit-sdk-dotnet) | [NuGet](https://www.nuget.org/packages/com.AppAmbit.Maui) |
| React Native | [appambit-sdk-react-native](https://github.com/AppAmbit/appambit-sdk-react-native) | [npm](https://www.npmjs.com/package/appambit) |
| .NET (WPF/WinUI) | [appambit-sdk-dotnet](https://github.com/AppAmbit/appambit-sdk-dotnet) | [NuGet](https://www.nuget.org/packages/com.AppAmbit.Sdk) |
| Avalonia | [appambit-sdk-dotnet](https://github.com/AppAmbit/appambit-sdk-dotnet) | [NuGet](https://www.nuget.org/packages/com.AppAmbit.Avalonia) |

---

## REST API

No SDK? No problem. Every capability (sessions, events, logs, breadcrumbs, consumers, CMS, and the database) is also reachable directly over HTTP, for web apps, backend services, or anything without a native SDK.

📖 [Getting started guide](https://docs.appambit.com/Rest/getting-started/)

---

## Troubleshooting

* **No data in dashboard** → check the app key, endpoint, and network access
* **Dependency not resolving** → run `flutter clean`, then `flutter pub get`
* **Crash not appearing** → crashes are sent on next launch
* **No breadcrumbs** → confirm `AppAmbitSdk()` is registered in `navigatorObservers`
* **Push not arriving** → confirm `google-services.json` (Android) or the APNs key and push capability (iOS), and that `PushNotificationsSdk.start()` runs after `AppAmbitSdk.start`

---

## Documentation

📚 [docs.appambit.com](https://docs.appambit.com)

---

## Community

- 💬 [Discord](https://discord.gg/nJyetYue2s)
- ✉️ [hello@appambit.com](mailto:hello@appambit.com)

---

## Pricing

Free plan with all core features, no credit card required. Paid plans start at $5.99/mo with hard spend caps, so there are no overage surprises.

🔗 [appambit.com](https://appambit.com) · [See pricing](https://appambit.com/pricing)

---

## License

Open source under the MIT License. See the [LICENSE](./LICENSE) file for the full terms.
