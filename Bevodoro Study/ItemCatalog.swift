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
        CatalogItem(key: "wheat", displayName: "Wheat", icon: "wheat", cost: 10),
        CatalogItem(key: "banana", displayName: "Banana", icon: "banana", cost: 15),
        CatalogItem(key: "orange", displayName: "Orange", icon: "orange", cost: 20),
        CatalogItem(key: "cookie", displayName: "Cookie", icon: "cookie", cost: 20),
        CatalogItem(key: "mango", displayName: "Mango", icon: "mango", cost: 25),
        CatalogItem(key: "homework", displayName: "Homework", icon: "homework", cost: 30),
        CatalogItem(key: "pill", displayName: "Pill", icon: "pill", cost: 60),
    ]

    static let medicineItems: [CatalogItem] = [
        CatalogItem(key: "pill", displayName: "Pill", icon: "pill", cost: 60),
    ]

    static let hatItems: [CatalogItem] = [
        CatalogItem(key: "bowBlue", displayName: "Blue bow", icon: "bowBlue", cost: 50),
        CatalogItem(key: "bowPink", displayName: "Pink bow", icon: "bowPink", cost: 50),
        CatalogItem(key: "bowPurple", displayName: "Purple bow", icon: "bowPurple", cost: 50),
        CatalogItem(key: "bowRed", displayName: "Red bow", icon: "bowRed", cost: 50),
        CatalogItem(key: "catearsWhite", displayName: "White cat ears", icon: "catearsWhite", cost: 55),
        CatalogItem(key: "topHat", displayName: "Top Hat", icon: "topHat", cost: 55),
        CatalogItem(key: "towerHeadband", displayName: "Tower headband", icon: "towerHeadband", cost: 65),
        CatalogItem(key: "crown", displayName: "Crown", icon: "crown", cost: 70),
    ]

    /// Default background; granted at signup (not sold for coins).
    static let dayBackgroundKey = "day"

    static let backgroundItems: [CatalogItem] = [
        CatalogItem(key: dayBackgroundKey, displayName: "Day", icon: "Background_Day", cost: 0),
        CatalogItem(key: "night", displayName: "Night", icon: "Background_Night", cost: 100),
        CatalogItem(key: "sky", displayName: "Sky", icon: "Background_Sky", cost: 120),
        CatalogItem(key: "blossom", displayName: "Blossom", icon: "Background_Blossom", cost: 150),
        CatalogItem(key: "sunset", displayName: "Sunset", icon: "Background_Sunset", cost: 130),
        CatalogItem(key: "speedway", displayName: "Speedway", icon: "Background_Speedway", cost: 130),
    ]

    static let shopCategories: [[CatalogItem]] = [
        foodItems, hatItems, backgroundItems
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
