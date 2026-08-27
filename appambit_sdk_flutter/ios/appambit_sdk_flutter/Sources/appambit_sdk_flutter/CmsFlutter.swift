import Foundation
import Flutter
import AppAmbit

public class CmsFlutter {

    private static var pendingRequests: [String: [() -> Void]] = [:]
    private static let pendingLock = NSLock()

    public static func getList(args: Any?, result: @escaping FlutterResult) {
        guard let argsDict = args as? [String: Any],
              let contentType = argsDict["contentType"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing 'contentType'", details: nil))
            return
        }

        pendingLock.lock()
        if pendingRequests[contentType] != nil {
            pendingRequests[contentType]?.append {
                self.doGetList(contentType: contentType, argsDict: argsDict) { items in
                    DispatchQueue.main.async { result(items) }
                }
            }
            pendingLock.unlock()
            return
        }
        pendingRequests[contentType] = []
        pendingLock.unlock()

        doGetList(contentType: contentType, argsDict: argsDict) { items in
            DispatchQueue.main.async { result(items) }
            
            pendingLock.lock()
            let waiting = pendingRequests.removeValue(forKey: contentType) ?? []
            pendingLock.unlock()
            
            for task in waiting {
                task()
            }
        }
    }

    private static func doGetList(contentType: String, argsDict: [String: Any], completion: @escaping ([Any]) -> Void) {
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
                    if let field = filter["field"] as? String {
                        let val: [String]
                        if let typed = filter["value"] as? [String] {
                            val = typed
                        } else if let nsArr = filter["value"] as? NSArray {
                            val = nsArr.compactMap { $0 as? String }
                        } else { break }
                        if !val.isEmpty { _ = query.inList(field, val) }
                    }
                case "notInList":
                    if let field = filter["field"] as? String {
                        let val: [String]
                        if let typed = filter["value"] as? [String] {
                            val = typed
                        } else if let nsArr = filter["value"] as? NSArray {
                            val = nsArr.compactMap { $0 as? String }
                        } else { break }
                        if !val.isEmpty { _ = query.notInList(field, val) }
                    }
                default:
                    break
                }
            }
        }

        query.getList { items in
            completion(items)
        }
    }
}
