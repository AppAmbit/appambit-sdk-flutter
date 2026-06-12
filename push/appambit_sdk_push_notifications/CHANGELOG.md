## Version 1.1.0

### AppAmbit SDK

* **[Feature]** Added database client for executing SQL, running batched/transactional operations, and querying data with a fluent query builder.

## Version 1.0.1

### AppAmbit SDK

* **[Refactor]** Removed `clearCmsCache` and `clearAllCmsCache` APIs across Android, iOS, and Dart layers. Callers must remove usages; cache management is now handled internally by the native SDK.
* **[Refactor]** CMS `inList()` / `notInList()` filters now delegate to native instead of performing client-side filtering. `page` / `perPage` are always forwarded to the platform call regardless of filter state.

## Version 1.0.0

### AppAmbit Push Notifications SDK

* **[Feature]** Added foreground, background, and opened notification listeners with cleanup callbacks (`setForegroundListener`, `setOpenedListener`, `PushNotificationsSdk.Android.setBackgroundListener`).
* **[Feature]** Added `PushNotificationData` model with platform-specific fields (`AndroidPushData`, `IosPushData`) covering color, icon, badge, channel, thread ID, and more.
* **[Feature]** Added Android background handler support via headless Flutter isolate — handles notifications when the app is killed. Handler must be a top-level or static function annotated `@pragma('vm:entry-point')`.
* **[Bugfix]** Fixed `setNotificationsEnabled` / `isNotificationsEnabled` SDK-level toggle with offline state sync to backend.
* **[Feature]** Added `requestNotificationPermissionWithResult` (async, returns granted status) and `hasNotificationPermission` (check the system permission without prompting).
* **[Refactor]** Renamed `hasSystemPermission` → `hasNotificationPermission` for API consistency.
* **[Feature]** Added iOS Notification Service Extension support — subclass `AppAmbitNotificationService` (pod `AppAmbitPushNotificationsExtension`) for rich notifications and image attachments.

## Version 0.3.0

### AppAmbit

* **[Feature]** Added support for CMS (Content Management System) integration, allowing dynamic content updates and management within the app without requiring app updates. Using fluent API design for easy integration and configuration of CMS features.

## Version 0.2.0

### AppAmbit Push Notifications SDK

* **[Feature]** Added Push Notifications support for Android and iOS. This includes handling push notification permissions and receiving notifications.

### AppAmbit SDK

* **[Feature]** Added Remote Config support to AppAmbit, allowing dynamic configuration of app behavior without requiring app updates.
* **[Feature]** Added option to send breadcrumbs only on crashes to improve performance and resource efficiency.