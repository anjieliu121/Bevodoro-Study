//
//  ItemCatalog.swift
//  Bevodoro Study
//
//  Created by Anjie on 3/11/26.
//

import Foundation

struct CatalogItem {
    let key: String
    let displayName: String
    let icon: String
    let cost: Int
}

struct ItemCatalog {
    static let foodItems: [CatalogItem] = [
        CatalogItem(key: "apple", displayName: "Apple", icon: "apple", cost: 10),
        CatalogItem(key: "banana", displayName: "Banana", icon: "banana", cost: 15),
        CatalogItem(key: "cookie", displayName: "Cookie", icon: "cookie", cost: 20),
        CatalogItem(key: "mango", displayName: "Mango", icon: "mango", cost: 25),
        CatalogItem(key: "orange", displayName: "Orange", icon: "orange", cost: 20),
    ]

    static let medicineItems: [CatalogItem] = [
        CatalogItem(key: "pill", displayName: "Pill", icon: "💊", cost: 60),
        CatalogItem(key: "syringe", displayName: "Syringe", icon: "💉", cost: 80),
        CatalogItem(key: "herb", displayName: "Herb", icon: "🌿", cost: 40),
    ]

    static let hatItems: [CatalogItem] = [
        CatalogItem(key: "bowBlue", displayName: "Blue bow", icon: "bowBlue", cost: 50),
        CatalogItem(key: "bowPink", displayName: "Pink bow", icon: "bowPink", cost: 50),
        CatalogItem(key: "bowPurple", displayName: "Purple bow", icon: "bowPurple", cost: 50),
        CatalogItem(key: "bowRed", displayName: "Red bow", icon: "bowRed", cost: 50),
        CatalogItem(key: "catearsWhite", displayName: "White cat ears", icon: "catearsWhite", cost: 55),
        CatalogItem(key: "crown", displayName: "Crown", icon: "crown", cost: 70),
        CatalogItem(key: "towerHeadband", displayName: "Tower headband", icon: "towerHeadband", cost: 65),
    ]

    /// Default background; granted at signup (not sold for coins).
    static let dayBackgroundKey = "day"

    static let backgroundItems: [CatalogItem] = [
        CatalogItem(key: dayBackgroundKey, displayName: "Day", icon: "Background_Day", cost: 0),
        CatalogItem(key: "night", displayName: "Night", icon: "bkgnight", cost: 100),
        CatalogItem(key: "sky", displayName: "Sky", icon: "bkgsky", cost: 120),
    ]

    static let shopCategories: [[CatalogItem]] = [
        foodItems, medicineItems, hatItems, backgroundItems
    ]

    private static let allItems: [CatalogItem] = foodItems + medicineItems + hatItems + backgroundItems

    static func icon(forKey key: String) -> String {
        return allItems.first(where: { $0.key == key })?.icon ?? "❓"
    }

    static func displayName(forKey key: String) -> String {
        return allItems.first(where: { $0.key == key })?.displayName ?? key
    }

    /// Asset name in the asset catalog (same as `icon` for background rows).
    static func backgroundAssetName(forKey key: String) -> String {
        backgroundItems.first(where: { $0.key == key })?.icon ?? "Background_Day"
    }
}
