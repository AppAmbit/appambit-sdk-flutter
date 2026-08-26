import AppAmbit
import Flutter
import Foundation

final class CloudCodeFlutter {
    private static let lock = NSLock()
    private static var requests: [String: PendingRequest] = [:]

    private final class PendingRequest {
        // Set once CloudCode.call(...) returns. Every completion path in the
        // native SDK (CloudCodeService.call) currently delivers via
        // DispatchQueue.main.async, so in practice the closure below never
        // runs before this is assigned - but that's an implementation detail
        // of a dependency we don't control, not part of its documented
        // contract. Registering the PendingRequest before calling
        // CloudCode.call (see `call` below) means a future synchronous
        // completion still finds it in `requests`, instead of silently
        // dropping the FlutterResult and leaking the entry - mirrors how the
        // Android bridge registers before attaching callbacks.
        var token: CloudCodeCancellationToken?
        let result: FlutterResult

        init(result: @escaping FlutterResult) {
            self.result = result
        }
    }

    static func call(args: Any?, result: @escaping FlutterResult) {
        guard let args = args as? [String: Any],
              let requestId = args["requestId"] as? String,
              !requestId.isEmpty,
              let function = args["function"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing Cloud Code arguments", details: nil))
            return
        }

        guard let method = method(from: args["method"] as? String) else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid Cloud Code HTTP method", details: nil))
            return
        }

        let query = args["query"] as? [String: String]
        let body = args["body"] as? [String: Any]
        let headers = args["headers"] as? [String: String]

        let pending = PendingRequest(result: result)
        lock.lock()
        requests[requestId] = pending
        lock.unlock()

        let token = CloudCode.call(
            function,
            method: method,
            query: query,
            body: body,
            headers: headers
        ) { response, error in
            guard let pending = remove(requestId) else { return }

            if let error {
                pending.result(FlutterError(
                    code: "CLOUD_CODE_ERROR",
                    message: error.localizedDescription,
                    details: errorDetails(error)
                ))
                return
            }

            guard let response else {
                pending.result(FlutterError(
                    code: "CLOUD_CODE_ERROR",
                    message: "Cloud Code returned no response",
                    details: ["code": "TRANSPORT"]
                ))
                return
            }

            pending.result([
                "data": response.data,
                "statusCode": response.statusCode,
                "requestId": response.requestId ?? NSNull(),
                "headers": response.headers,
            ])
        }

        lock.lock()
        pending.token = token
        lock.unlock()
    }

    static func cancel(args: Any?, result: @escaping FlutterResult) {
        guard let args = args as? [String: Any],
              let requestId = args["requestId"] as? String,
              !requestId.isEmpty else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing 'requestId'", details: nil))
            return
        }

        if let pending = remove(requestId) {
            pending.token?.cancel()
            pending.result(FlutterError(
                code: "CLOUD_CODE_ERROR",
                message: "Cloud Code request was cancelled",
                details: ["code": "CANCELLED"]
            ))
        }
        result(nil)
    }

    /// Mirrors CloudCodeFlutter.kt's detach(): fails every still-pending
    /// request instead of leaking its FlutterResult and cancellation token
    /// past engine teardown (e.g. a hot restart).
    static func detach() {
        lock.lock()
        let pending = requests
        requests.removeAll()
        lock.unlock()

        for (_, request) in pending {
            request.token?.cancel()
            request.result(FlutterError(
                code: "CLOUD_CODE_ERROR",
                message: "Cloud Code request was cancelled",
                details: ["code": "CANCELLED"]
            ))
        }
    }

    private static func method(from value: String?) -> CloudCodeHttpMethod? {
        switch value?.uppercased() {
        case "GET": return .get
        case "POST": return .post
        case "PUT": return .put
        case "PATCH": return .patch
        case "DELETE": return .delete
        default: return nil
        }
    }

    private static func remove(_ requestId: String) -> PendingRequest? {
        lock.lock()
        defer { lock.unlock() }
        return requests.removeValue(forKey: requestId)
    }

    private static func errorDetails(_ error: Error) -> [String: Any] {
        guard let cloudError = error as? CloudCodeError else {
            return [
                "code": "TRANSPORT",
                "message": error.localizedDescription,
            ]
        }

        var details: [String: Any] = [
            "code": errorCode(cloudError),
            "message": cloudError.localizedDescription,
        ]
        switch cloudError {
        case .invalidFunction(let function):
            details["function"] = function
        case .invalidHeader(let header):
            details["header"] = header
        default:
            break
        }
        let userInfo = (cloudError as NSError).userInfo
        details["statusCode"] = userInfo[CloudCodeErrorKeys.statusCode]
        details["body"] = userInfo[CloudCodeErrorKeys.body]
        details["rawBody"] = userInfo[CloudCodeErrorKeys.rawBody]
        details["requestId"] = userInfo[CloudCodeErrorKeys.requestId]
        return details
    }

    private static func errorCode(_ error: CloudCodeError) -> String {
        switch error {
        case .notInitialized: return "NOT_INITIALIZED"
        case .invalidFunction: return "INVALID_FUNCTION"
        case .invalidBody: return "INVALID_BODY"
        case .invalidHeader: return "INVALID_HEADER"
        case .networkUnavailable: return "NETWORK_UNAVAILABLE"
        case .timedOut: return "TIMED_OUT"
        case .invalidURL: return "INVALID_URL"
        case .transport: return "TRANSPORT"
        case .decoding: return "DECODING"
        case .http: return "HTTP"
        }
    }
}
