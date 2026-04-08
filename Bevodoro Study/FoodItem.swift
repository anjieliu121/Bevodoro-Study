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
    /// `pill` is not listed — placement is handled by `applyPillPlacement` (first when sick, last when healthy).
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

    /// Read `food` (canonical, matches `User`) or legacy `foods` from a user document’s raw `[String: Any]`.
    ///
    /// **`food` must win when both exist:** the app persists counts only under `food` (`User.saveToFirestore`).
    /// If we preferred `foods` first, a stale duplicate field would keep showing items after the last one was eaten.
    static func parseFoodMap(from documentData: [String: Any]?) -> [String: Int] {
        guard let data = documentData else { return [:] }

        if data["food"] != nil {
            if let rawMap = data["food"] as? [String: Any] {
                return intCounts(fromFirestoreAnyMap: rawMap)
            }
            if let legacy = data["food"] as? [String: Int] {
                return legacy
            }
        }

        if let rawMap = data["foods"] as? [String: Any] {
            return intCounts(fromFirestoreAnyMap: rawMap)
        }
        if let legacy = data["foods"] as? [String: Int] {
            return legacy
        }
        return [:]
    }

    /// Read `medicine` from a user document’s raw `[String: Any]`.
    ///
    /// Supports:
    /// - `[String: Int]` / `[String: Any]` (current)
    /// - `[String]` (legacy array of keys; duplicates count)
    static func parseMedicineMap(from documentData: [String: Any]?) -> [String: Int] {
        guard let data = documentData else { return [:] }

        if let rawMap = data["medicine"] as? [String: Any] {
            return intCounts(fromFirestoreAnyMap: rawMap)
        }
        if let legacy = data["medicine"] as? [String: Int] {
            return legacy
        }
        if let arr = data["medicine"] as? [String] {
            var out: [String: Int] = [:]
            for key in arr {
                out[key, default: 0] += 1
            }
            return out
        }
        return [:]
    }

    private static func intCounts(fromFirestoreAnyMap rawMap: [String: Any]) -> [String: Int] {
        var out: [String: Int] = [:]
        for (key, value) in rawMap {
            if let q = intFromFirestore(value) {
                out[key] = q
            }
        }
        return out
    }

    /// Moves `pill` to the start when Bevo is sick, or to the end when healthy. Other items keep relative order.
    static func applyPillPlacement(to items: [FoodItem], sickBevo: Bool) -> [FoodItem] {
        guard let idx = items.firstIndex(where: { $0.imageName == "pill" }) else { return items }
        var out = items
        let pill = out.remove(at: idx)
        if sickBevo {
            out.insert(pill, at: 0)
        } else {
            out.append(pill)
        }
        return out
    }

    /// Only foods with quantity > 0, sorted for the trough UI.
    static func troughItems(fromFoodMap map: [String: Int], sickBevo: Bool) -> [FoodItem] {
        let items = map.compactMap { key, qty -> FoodItem? in
            guard qty > 0 else { return nil }
            return FoodItem(imageName: key, quantity: qty)
        }
        let sorted = items.sorted { a, b in
            let ia = troughDisplayOrder.firstIndex(of: a.imageName) ?? Int.max
            let ib = troughDisplayOrder.firstIndex(of: b.imageName) ?? Int.max
            if ia != ib { return ia < ib }
            return a.imageName < b.imageName
        }
        return applyPillPlacement(to: sorted, sickBevo: sickBevo)
    }
}
