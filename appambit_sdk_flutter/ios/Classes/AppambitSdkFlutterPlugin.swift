import Flutter
import UIKit
import AppAmbitSdk

public class AppAmbitSdkFlutterPlugin: NSObject, FlutterPlugin {

  // Channels
  private static let coreChannelName      = "com.appambit/appambitcore"
  private static let analyticsChannelName = "com.appambit/analytics"
  private static let crashesChannelName   = "com.appambit/crashes"

  
  private enum Scope { case core, analytics, crashes }
  private let scope: Scope

  private init(scope: Scope) {
    self.scope = scope
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    // Core
    let coreChannel = FlutterMethodChannel(name: coreChannelName, binaryMessenger: registrar.messenger())
    let coreInstance = AppAmbitSdkFlutterPlugin(scope: .core)
    registrar.addMethodCallDelegate(coreInstance, channel: coreChannel)

    // Analytics
    let analyticsChannel = FlutterMethodChannel(name: analyticsChannelName, binaryMessenger: registrar.messenger())
    let analyticsInstance = AppAmbitSdkFlutterPlugin(scope: .analytics)
    registrar.addMethodCallDelegate(analyticsInstance, channel: analyticsChannel)

    // Crashes
    let crashesChannel = FlutterMethodChannel(name: crashesChannelName, binaryMessenger: registrar.messenger())
    let crashesInstance = AppAmbitSdkFlutterPlugin(scope: .crashes)
    registrar.addMethodCallDelegate(crashesInstance, channel: crashesChannel)
  }


  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch scope {

    case .core:
      switch call.method {
      case "start":
        guard
          let args = call.arguments as? [String: Any],
          let appKey = args["appKey"] as? String,
          !appKey.isEmpty
        else {
          result(FlutterError(code: "BAD_ARGS", message: "Missing 'appKey'", details: nil))
          return
        }
        DispatchQueue.main.async {
          AppAmbit.start(appKey: appKey)
          result(nil)
        }

      case "addBreadcrumb":
        guard
          let args = call.arguments as? [String: Any],
          let name = args["name"] as? String,
          !name.isEmpty
        else {
          result(FlutterError(code: "BAD_ARGS", message: "Missing 'name'", details: nil))
          return
        }
        AppAmbit.addBreadcrumb(name: name)

      default:
        result(FlutterMethodNotImplemented)
      }

    case .analytics:
      switch call.method {
      case "setUserId":          AnalyticsFlutter.setUserId(args: call.arguments, result: result)
      case "setEmail":           AnalyticsFlutter.setEmail(args: call.arguments, result: result)
      case "clearToken":         AnalyticsFlutter.clearToken(result: result)
      case "startSession":       AnalyticsFlutter.startSession(result: result)
      case "endSession":         AnalyticsFlutter.endSession(result: result)
      case "enableManualSession":AnalyticsFlutter.enableManualSession(result: result)
      case "trackEvent":         AnalyticsFlutter.trackEvent(args: call.arguments, result: result)
      case "generateTestEvent":  AnalyticsFlutter.generateTestEvent(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }

    case .crashes:
      switch call.method {
      case "didCrashInLastSession": CrashesFlutter.didCrashInLastSession(result: result)
      case "generateTestCrash":     CrashesFlutter.generateTestCrash(result: result)
      case "logError":              CrashesFlutter.logError(args: call.arguments, result: result)
      case "logErrorMessage":       CrashesFlutter.logErrorMessage(args: call.arguments, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
