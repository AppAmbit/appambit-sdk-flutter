import Flutter
import AppAmbit

public class DatabaseFlutter {

    public static func execute(args: Any?, result: @escaping FlutterResult) {
        guard let argsDict = args as? [String: Any],
              let sql = argsDict["sql"] as? String, !sql.isEmpty else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing 'sql'", details: nil))
            return
        }

        let params = argsDict["params"] as? [Any]

        let completion: (DbResult?, Error?) -> Void = { dbResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(Self.errorMap(Self.errorMessage(error)))
                    return
                }
                guard let dbResult = dbResult else {
                    result(Self.errorMap("No result returned"))
                    return
                }
                result(Self.toMap(dbResult))
            }
        }

        if let params = params, !params.isEmpty {
            AppAmbitDb.execute(sql, params: params, completion: completion)
        } else {
            AppAmbitDb.execute(sql, completion: completion)
        }
    }

    public static func batch(args: Any?, result: @escaping FlutterResult) {
        guard let argsDict = args as? [String: Any],
              let statementsRaw = argsDict["statements"] as? [[String: Any]] else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing 'statements'", details: nil))
            return
        }

        let inTransaction = (argsDict["inTransaction"] as? Bool) ?? false

        let statements = statementsRaw.map { s -> DbStatement in
            let sql = (s["sql"] as? String) ?? ""
            let params = s["params"] as? [Any]
            return DbStatement(sql: sql, params: params)
        }

        let completion: ([DbResult]?, Error?) -> Void = { results, error in
            DispatchQueue.main.async {
                if let error = error {
                    result([Self.errorMap(Self.errorMessage(error))])
                    return
                }
                result((results ?? []).map { Self.toMap($0) })
            }
        }

        if inTransaction {
            AppAmbitDb.batchInTransaction(statements, completion: completion)
        } else {
            AppAmbitDb.batch(statements, completion: completion)
        }
    }

    private static func toMap(_ r: DbResult) -> [String: Any] {
        let error: Any = r.error != nil ? r.error! : NSNull()
        return [
            "columns": r.columns,
            "rows": r.rows,
            "rowsRead": r.rowsRead,
            "rowsWritten": r.rowsWritten,
            "error": error,
        ]
    }

    private static func errorMessage(_ error: Error) -> String {
        let ns = error as NSError
        if ns.domain == "AppAmbit.ApiErrorType" {
            switch ns.code {
            case 1: return "Unauthorized"
            case 2: return "Network Unavailable"
            case 3: return "Unknown API error"
            default: return "API error (code \(ns.code))"
            }
        }
        return error.localizedDescription
    }

    private static func errorMap(_ msg: String) -> [String: Any] {
        return [
            "columns": [String](),
            "rows": [[Any]](),
            "rowsRead": 0,
            "rowsWritten": 0,
            "error": msg,
        ]
    }
}
