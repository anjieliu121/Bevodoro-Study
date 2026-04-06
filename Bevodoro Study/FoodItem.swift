//
//  FoodItem.swift
//  Bevodoro Study
//
//  One row in the food trough: an Assets image name + how many the user owns.
//  Built from Firestore: users/{uid} with a map field `food` or `foods` (see parseFoodMap).
//

import Foundation

struct FoodItem: Hashable {
    /// Must match the image set name in Assets.xcassets (e.g. "apple").
    let imageName: String
    /// How many of this food the user has (shown as a badge on the cell).
    var quantity: Int

    init(imageName: String, quantity: Int) {
        self.imageName = imageName
        self.quantity = max(0, quantity)
    }
}

// MARK: - Firestore helpers (beginner-friendly)

extension FoodItem {

    /// Order foods in the trough (unknown keys sort alphabetically after these).
    static let troughDisplayOrder: [String] = [
        "apple", "banana", "mango", "cookie", "orange",
        "strawberry", "watermelon", "milk", "bread"
    ]

    /// Turn Firestore map values into ints (handles Int and Int64).
    private static func intFromFirestore(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let i = value as? Int64 { return Int(i) }
        if let n = value as? NSNumber { return n.intValue }
        return nil
    }

    /// Read `foods` or `food` map from a user document’s raw `[String: Any]`.
    static func parseFoodMap(from documentData: [String: Any]?) -> [String: Int] {
        guard let data = documentData else { return [:] }

        let rawMap: [String: Any]? =
            (data["foods"] as? [String: Any])
            ?? (data["food"] as? [String: Any])

        guard let rawMap else {
            if let legacy = data["food"] as? [String: Int] { return legacy }
            if let legacy = data["foods"] as? [String: Int] { return legacy }
            return [:]
        }

        var out: [String: Int] = [:]
        for (key, value) in rawMap {
            if let q = intFromFirestore(value) {
                out[key] = q
            }
        }
        return out
    }

    /// Only foods with quantity > 0, sorted for the trough UI.
    static func troughItems(fromFoodMap map: [String: Int]) -> [FoodItem] {
        let items = map.compactMap { key, qty -> FoodItem? in
            guard qty > 0 else { return nil }
            return FoodItem(imageName: key, quantity: qty)
        }
        return items.sorted { a, b in
            let ia = troughDisplayOrder.firstIndex(of: a.imageName) ?? Int.max
            let ib = troughDisplayOrder.firstIndex(of: b.imageName) ?? Int.max
            if ia != ib { return ia < ib }
            return a.imageName < b.imageName
        }
    }
}
