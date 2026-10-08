# Consumer ProGuard/R8 rules for appambit_sdk_flutter.
#
# Applied automatically to every app that depends on this plugin. They only
# take effect in release builds: the Flutter Gradle plugin sets
# `isMinifyEnabled = true` on the release build type (FlutterPlugin.kt), so
# release APKs/AABs are shrunk and obfuscated while debug builds are not.
# Anything the SDK reaches by reflection rather than by a static reference
# therefore survives debug and disappears in release.

# The native SDK serializes and deserializes every wire payload through
# java.lang.reflect.Field - JsonConvertUtils/JsonDeserializer read
# Field.getName() and instantiate models via a no-arg constructor. Obfuscating
# those field names silently changes the JSON the backend receives, which
# looks like "the SDK stopped sending anything".
#
# `com.appambit:appambit` currently ships an equivalent proguard.txt inside
# the AAR, so these are deliberately redundant. They are kept here so that
# telemetry cannot break silently if a future release of the native AAR ships
# without its consumer rules - the failure mode is a wire-format change with
# no crash and no log, which is extremely hard to diagnose from the app side.
-keepattributes RuntimeVisibleAnnotations,RuntimeInvisibleAnnotations,AnnotationDefault

-keep @interface com.appambit.sdk.utils.JsonKey
-keep @interface com.appambit.sdk.annotations.DbColumn

-keepclassmembers class com.appambit.sdk.models.** {
    <fields>;
    public <init>();
}

# Models defined by the app itself can opt into stable JSON/column names with
# the SDK's annotations; keep those members wherever they live.
-keepclassmembers class * {
    @com.appambit.sdk.utils.JsonKey <fields>;
    @com.appambit.sdk.annotations.DbColumn <fields>;
}

# Entry points of this plugin. The Flutter embedding reaches
# AppAmbitSdkFlutterPlugin through GeneratedPluginRegistrant, and that class
# wires up the per-domain channel bridges; keep the whole set so a shrinking
# regression cannot leave an engine attached to a half-registered plugin.
# See https://github.com/flutter/flutter/issues/154580.
-keep class com.appambit.appambit_sdk_flutter.AppAmbitSdkFlutterPlugin { *; }
-keep class com.appambit.appambit_sdk_flutter.AnalyticsFlutter { *; }
-keep class com.appambit.appambit_sdk_flutter.CrashesFlutter { *; }
-keep class com.appambit.appambit_sdk_flutter.RemoteConfigFlutter { *; }
-keep class com.appambit.appambit_sdk_flutter.CmsFlutter { *; }
-keep class com.appambit.appambit_sdk_flutter.DatabaseFlutter { *; }
-keep class com.appambit.appambit_sdk_flutter.CloudCodeFlutter { *; }

# The crash handler installs a Thread.UncaughtExceptionHandler and replays
# crash files on the next launch; keep the handler and the file-format classes
# it reads back, since a renamed field would make a stored crash undecodable.
-keep class com.appambit.sdk.CrashHandler { *; }
-keepclassmembers class com.appambit.sdk.crashFileGenerator.** {
    <fields>;
    public <init>();
}
