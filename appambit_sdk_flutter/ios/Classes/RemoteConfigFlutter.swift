import Flutter
import UIKit
import AppAmbitSdk

public class RemoteConfigFlutter {
    
    public static func enable(result: @escaping FlutterResult) {
        RemoteConfig.enable()
        result(true)
    }
    
    public static func getString(args: Any?, result: @escaping FlutterResult) {
        guard let argsDict = args as? [String: Any],
              let key = argsDict["key"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing or invalid 'key'", details: nil))
            return
        }
        let value = RemoteConfig.getString(key)
        result(value)
    }
    
    public static func getBoolean(args: Any?, result: @escaping FlutterResult) {
        guard let argsDict = args as? [String: Any],
              let key = argsDict["key"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing or invalid 'key'", details: nil))
            return
        }
        let value = RemoteConfig.getBoolean(key)
        result(value)
    }
    
    public static func getInt(args: Any?, result: @escaping FlutterResult) {
        guard let argsDict = args as? [String: Any],
              let key = argsDict["key"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing or invalid 'key'", details: nil))
            return
        }
        let value = RemoteConfig.getInt(key)
        result(value)
    }
    
    public static func getDouble(args: Any?, result: @escaping FlutterResult) {
        guard let argsDict = args as? [String: Any],
              let key = argsDict["key"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing or invalid 'key'", details: nil))
            return
        }
        let value = RemoteConfig.getDouble(key)
        result(value)
    }
}
