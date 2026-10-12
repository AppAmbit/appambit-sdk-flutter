# Consumer ProGuard/R8 rules for appambit_sdk_push_notifications.
#
# These are applied automatically to every app that depends on this plugin.
# They matter only in release builds: the Flutter Gradle plugin sets
# `isMinifyEnabled = true` on the release build type (FlutterPlugin.kt), so
# R8 shrinks and obfuscates release APKs/AABs while debug builds are left
# untouched. That asymmetry is why push worked in debug and went silent in
# release.
#
# Note that `com.appambit:appambit.push.notifications` ships an EMPTY
# proguard.txt, so nothing here comes from the native AAR - the plugin has to
# declare its own keeps.

# The AppAmbit Android SDK instantiates this bridge reflectively, resolving it
# by the fully-qualified name declared as meta-data in this plugin's
# AndroidManifest:
#
#   <meta-data android:name="com.appambit.sdk.NotificationServiceExtension"
#              android:value="com.example.appambit_sdk_push_notifications.AppambitFlutterPushExtension"/>
#
# R8 does not treat a meta-data *value* as a class reference, so without this
# rule the class has no reachable root: R8 renames it and strips its no-arg
# constructor, both onNotificationBackground overloads, both
# onNotificationForeground overloads, every field, and the Companion object
# that holds saveHandles/clearHandles. The SDK's Class.forName then fails and
# background/killed-app pushes never reach the Dart handler.
-keep class com.example.appambit_sdk_push_notifications.AppambitFlutterPushExtension { *; }

# AppambitFlutterPushExtension is `open` so developers can subclass it and
# point the meta-data at their own class. Those subclasses are reached the
# same reflective way and need the same protection, as does the SDK interface
# they implement (R8 strips its abstract methods once no implementation
# survives).
-keep class com.appambit.sdk.IAppAmbitNotificationServiceExtension { *; }
-keep class * implements com.appambit.sdk.IAppAmbitNotificationServiceExtension { *; }

# The background bridge boots a headless FlutterEngine from the
# FirebaseMessagingService process and looks the Dart entry point up through
# FlutterCallbackInformation. Keep that lookup path intact.
-keep class io.flutter.view.FlutterCallbackInformation { *; }
-keep class io.flutter.embedding.engine.dart.DartExecutor$DartCallback { *; }

# The payload model the bridge hands to Dart is populated by the native SDK's
# reflective JSON mapper, which reads field names at runtime.
-keepclassmembers class com.appambit.sdk.models.AppAmbitNotification {
    <fields>;
    public <init>();
}
