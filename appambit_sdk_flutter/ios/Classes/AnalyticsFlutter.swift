import Foundation
import Flutter
import AppAmbitSdk

final class AnalyticsFlutter {

  static func setUserId(args: Any?, result: @escaping FlutterResult) {
    guard
      let dict = args as? [String: Any],
      let userId = dict["userId"] as? String
    else {
      result(FlutterError(code: "BAD_ARGS", message: "Missing 'userId'", details: nil))
      return
    }
    Analytics.setUserId(userId) { err in
      if let err { result(FlutterError(code: "SET_USER_ID_ERR", message: err.localizedDescription, details: nil)) }
      else { result(nil) }
    }
  }

  static func setEmail(args: Any?, result: @escaping FlutterResult) {
    guard
      let dict = args as? [String: Any],
      let email = dict["email"] as? String
    else {
      result(FlutterError(code: "BAD_ARGS", message: "Missing 'email'", details: nil))
      return
    }
    // Tu implementación actual no llama completion; resolvemos inmediatamente
    Analytics.setEmail(email) { _ in }
    result(nil)
  }

  static func clearToken(result: @escaping FlutterResult) {
    Analytics.clearToken()
    result(nil)
  }

  static func startSession(result: @escaping FlutterResult) {
    Analytics.startSession { err in
      if let err { result(FlutterError(code: "START_SESSION_ERR", message: err.localizedDescription, details: nil)) }
      else { result(nil) }
    }
  }

  static func endSession(result: @escaping FlutterResult) {
    Analytics.endSession { err in
      if let err { result(FlutterError(code: "END_SESSION_ERR", message: err.localizedDescription, details: nil)) }
      else { result(nil) }
    }
  }

  static func enableManualSession(result: @escaping FlutterResult) {
    Analytics.enableManualSession()
    result(nil)
  }

  static func trackEvent(args: Any?, result: @escaping FlutterResult) {
    guard
      let dict = args as? [String: Any],
      let name = dict["name"] as? String,
      let props = dict["properties"] as? [String: String]
    else {
      result(FlutterError(code: "BAD_ARGS",
                          message: "Expected {name:String, properties:Map<String,String>}",
                          details: nil))
      return
    }


    Analytics.trackEvent(
      eventTitle: name,
      data: props
    ) { err in
      if let err { result(FlutterError(code: "TRACK_EVENT_ERR", message: err.localizedDescription, details: nil)) }
      else { result(nil) }
    }
  }

  static func generateTestEvent(result: @escaping FlutterResult) {
    Analytics.generateTestEvent { err in
      if let err { result(FlutterError(code: "GEN_TEST_EVENT_ERR", message: err.localizedDescription, details: nil)) }
      else { result(nil) }
    }
  }
}
