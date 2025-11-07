import Foundation
import Flutter
import AppAmbitSdk


final class CrashesFlutter {
 
  static func didCrashInLastSession(result: @escaping FlutterResult) {
    Crashes.didCrashInLastSession { didCrash in
      result(didCrash)
    }
  }

  static func generateTestCrash(result: @escaping FlutterResult) {
    Crashes.generateTestCrash()
  }

    static func logError(args: Any?, result: @escaping FlutterResult) {
      guard let dict = args as? [String: Any]? else {
        result(FlutterError(code: "BAD_ARGS", message: "Expected Map or null", details: nil))
        return
      }

      let properties = dict?["properties"] as? [String: String]
      let classFqn   = dict?["classFqn"] as? String
      let fileName   = dict?["fileName"] as? String
      let lineNumber = (dict?["lineNumber"] as? NSNumber)?.int64Value
                       ?? Int64(dict?["lineNumber"] as? Int ?? #line)

      func errorFromExceptionMap(_ exc: [String: Any]) -> Error {
        let message = (exc["message"] as? String) ?? (exc["description"] as? String) ?? "Unknown exception"
        let code = (exc["code"] as? Int) ?? 0

        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: message]

        if let stack = exc["stackTrace"] as? String {
          userInfo["stackTrace"] = stack
        }
        if let source = exc["source"] as? String {
          userInfo["source"] = source
        }
        if let inner = exc["innerException"] as? String {
          userInfo["innerException"] = inner
        }

        for (k, v) in exc {
          if userInfo[k] == nil {
            userInfo[k] = v
          }
        }

        return NSError(domain: "com.appambit.flutter.error", code: code, userInfo: userInfo)
      }

      var exceptionError: Error? = nil
      if let excMap = dict?["exception"] as? [String: Any] {
        exceptionError = errorFromExceptionMap(excMap)
      } else if let msg = dict?["message"] as? String ?? dict?["errorMessage"] as? String {
        var exc: [String: Any] = ["message": msg]
        if let stack = dict?["stackTrace"] as? String { exc["stackTrace"] = stack }
        exceptionError = errorFromExceptionMap(exc)
      } else if dict == nil {
        exceptionError = nil
      } else {
        exceptionError = nil
      }

      Crashes.logError(
        exception: exceptionError,
        properties: properties,
        classFqn: classFqn,
        fileName: fileName,
        lineNumber: lineNumber
      ) { err in
        if let err {
          result(FlutterError(code: "LOG_ERROR_ERR", message: err.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }


  static func logErrorMessage(args: Any?, result: @escaping FlutterResult) {
    guard
      let dict = args as? [String: Any],
      let message = dict["message"] as? String
    else {
      result(FlutterError(code: "BAD_ARGS", message: "Missing 'message'", details: nil))
      return
    }

    let properties = dict["properties"] as? [String: String]
    let classFqn   = dict["classFqn"] as? String
    let fileName   = dict["fileName"] as? String
    let lineNumber = (dict["lineNumber"] as? NSNumber)?.int64Value
                     ?? Int64(dict["lineNumber"] as? Int ?? #line)

    Crashes.logError(
      message: message,
      properties: properties,
      classFqn: classFqn,
      fileName: fileName,
      lineNumber: lineNumber
    ) { err in
      if let err { result(FlutterError(code: "LOG_ERROR_MSG_ERR", message: err.localizedDescription, details: nil)) }
      else { result(nil) }
    }
  }
}
