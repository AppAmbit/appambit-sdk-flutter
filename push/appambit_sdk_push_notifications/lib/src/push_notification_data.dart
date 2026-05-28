/// Parsed notification payload delivered by AppAmbit push.
///
/// Fields mirror the cross-platform surface used by the .NET SDK
/// (`PushNotificationData`). Platform-specific extras are exposed
/// via [android] and [ios].
class PushNotificationData {
  final String? title;
  final String? body;
  final String? imageUrl;
  final Map<String, String>? data;
  final AndroidPushData? android;
  final IosPushData? ios;

  const PushNotificationData({
    this.title,
    this.body,
    this.imageUrl,
    this.data,
    this.android,
    this.ios,
  });

  factory PushNotificationData.fromMap(Map<dynamic, dynamic> map) {
    Map<String, String>? data;
    final raw = map['data'];
    if (raw is Map) {
      data = <String, String>{
        for (final entry in raw.entries)
          entry.key.toString(): entry.value?.toString() ?? '',
      };
    }
    return PushNotificationData(
      title: map['title'] as String?,
      body: map['body'] as String?,
      imageUrl: map['imageUrl'] as String?,
      data: data,
      android: map['android'] is Map
          ? AndroidPushData.fromMap(map['android'] as Map)
          : null,
      ios: map['ios'] is Map
          ? IosPushData.fromMap(map['ios'] as Map)
          : null,
    );
  }
}

/// Android-specific push payload extras.
///
/// The Android SDK already applies these fields to `NotificationCompat.Builder`
/// before posting; they are surfaced here so a customizer or listener can read
/// what the backend sent.
class AndroidPushData {
  final String? color;
  final String? smallIconName;
  final String? ticker;
  final bool? sticky;
  final String? visibility;
  final String? channelId;
  final String? priority;
  final String? tag;
  final String? sound;
  final String? clickAction;

  const AndroidPushData({
    this.color,
    this.smallIconName,
    this.ticker,
    this.sticky,
    this.visibility,
    this.channelId,
    this.priority,
    this.tag,
    this.sound,
    this.clickAction,
  });

  factory AndroidPushData.fromMap(Map<dynamic, dynamic> map) =>
      AndroidPushData(
        color: map['color'] as String?,
        smallIconName: map['smallIconName'] as String?,
        ticker: map['ticker'] as String?,
        sticky: map['sticky'] as bool?,
        visibility: map['visibility'] as String?,
        channelId: map['channelId'] as String?,
        priority: map['priority'] as String?,
        tag: map['tag'] as String?,
        sound: map['sound'] as String?,
        clickAction: map['clickAction'] as String?,
      );
}

/// iOS-specific push payload extras.
///
/// Surfaces the standard `aps` fields the SDK forwards to Dart. The raw `aps`
/// dictionary itself is not copied into [PushNotificationData.data].
class IosPushData {
  final int? badge;
  final String? sound;
  final String? category;
  final String? threadId;

  const IosPushData({
    this.badge,
    this.sound,
    this.category,
    this.threadId,
  });

  factory IosPushData.fromMap(Map<dynamic, dynamic> map) => IosPushData(
        badge: (map['badge'] as num?)?.toInt(),
        sound: map['sound'] as String?,
        category: map['category'] as String?,
        threadId: map['threadId'] as String?,
      );
}
