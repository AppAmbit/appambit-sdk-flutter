import Foundation
import Flutter
import AppAmbit

public class CmsFlutter {

    public static func clearCache(args: Any?, result: @escaping FlutterResult) {
        let argsDict = args as? [String: Any]
        if let contentType = argsDict?["contentType"] as? String {
            Cms.clearCache(contentType)
        }
        result(nil)
    }

    public static func clearAllCache(result: @escaping FlutterResult) {
        Cms.clearAllCache()
        result(nil)
    }

    public static func getList(args: Any?, result: @escaping FlutterResult) {
        guard let argsDict = args as? [String: Any],
              let contentType = argsDict["contentType"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing 'contentType'", details: nil))
            return
        }

        let query = Cms.contentTypelessObjC(contentType)

        if let page = argsDict["page"] as? Int {
            _ = query.getPage(page)
        }

        if let perPage = argsDict["perPage"] as? Int {
            _ = query.getPerPage(perPage)
        }

        if let orderBy = argsDict["orderBy"] as? String {
            if let orderDir = argsDict["orderDir"] as? String, orderDir == "desc" {
                _ = query.orderByDescending(orderBy)
            } else {
                _ = query.orderByAscending(orderBy)
            }
        }

        if let filters = argsDict["filters"] as? [[String: Any]] {
            for filter in filters {
                guard let type = filter["type"] as? String else { continue }

                switch type {
                case "search":
                    if let q = filter["query"] as? String { _ = query.search(q) }
                case "equals":
                    if let field = filter["field"] as? String,
                       let val = filter["value"] as? String { _ = query.equals(field, val) }
                case "notEquals":
                    if let field = filter["field"] as? String,
                       let val = filter["value"] as? String { _ = query.notEquals(field, val) }
                case "contains":
                    if let field = filter["field"] as? String,
                       let val = filter["value"] as? String { _ = query.contains(field, val) }
                case "startsWith":
                    if let field = filter["field"] as? String,
                       let val = filter["value"] as? String { _ = query.startsWith(field, val) }
                case "greaterThan":
                    if let field = filter["field"] as? String,
                       let val = filter["value"] { _ = query.greaterThan(field, val) }
                case "greaterThanOrEqual":
                    if let field = filter["field"] as? String,
                       let val = filter["value"] { _ = query.greaterThanOrEqual(field, val) }
                case "lessThan":
                    if let field = filter["field"] as? String,
                       let val = filter["value"] { _ = query.lessThan(field, val) }
                case "lessThanOrEqual":
                    if let field = filter["field"] as? String,
                       let val = filter["value"] { _ = query.lessThanOrEqual(field, val) }
                case "inList":
                    if let field = filter["field"] as? String,
                       let val = filter["value"] as? [String] { _ = query.inList(field, val) }
                case "notInList":
                    if let field = filter["field"] as? String,
                       let val = filter["value"] as? [String] { _ = query.notInList(field, val) }
                default:
                    break
                }
            }
        }

        query.getList { items in
            DispatchQueue.main.async {
                result(items)
            }
        }
    }
}
