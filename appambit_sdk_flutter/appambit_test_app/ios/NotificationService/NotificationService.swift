import UserNotifications
import AppAmbitPushNotificationsExtension

/// AppAmbit Notification Service Extension for the Flutter test app.
///
/// Subclasses `AppAmbitNotificationService` so the SDK handles image
/// attachment download and final delivery. Mutates content in `didReceive`,
/// then forwards a new request to the base class — same shape as the
/// `SampleNotificationService` in the AppAmbit iOS SDK.
class NotificationService: AppAmbitNotificationService {

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            NSLog("[AppAmbitPushSDK] NotificationService: Failed to create mutable content copy.")
            contentHandler(request.content)
            return
        }

        NSLog("[AppAmbitPushSDK] NotificationService: Processing notification -> %@", bestAttemptContent.title)

        let userInfo = bestAttemptContent.userInfo
        let dataPayload = userInfo["data"] as? [AnyHashable: Any] ?? userInfo

        bestAttemptContent.title += " Customs"

        if let category = dataPayload["category_type"] as? String {
            bestAttemptContent.categoryIdentifier = category
        }

        if let threadId = dataPayload["chat_id"] as? String {
            bestAttemptContent.threadIdentifier = threadId
        }

        if #available(iOS 15.0, *) {
            if let isUrgent = dataPayload["is_urgent"] as? String, isUrgent == "true" {
                bestAttemptContent.interruptionLevel = .timeSensitive
            }
        }

        if let badgeCountString = dataPayload["badge_count"] as? String,
           let badgeCount = Int(badgeCountString) {
            bestAttemptContent.badge = NSNumber(value: badgeCount)
        }

        let newRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: bestAttemptContent,
            trigger: request.trigger
        )

        NSLog("[AppAmbitPushSDK] NotificationService: Content modified, delegating to parent handler.")
        super.didReceive(newRequest, withContentHandler: contentHandler)
    }

    override func serviceExtensionTimeWillExpire() {
        NSLog("[AppAmbitPushSDK] NotificationService: Time limit reached — delivering best attempt content.")
        super.serviceExtensionTimeWillExpire()
    }
}
