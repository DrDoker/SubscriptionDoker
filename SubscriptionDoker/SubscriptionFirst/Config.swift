//
//  Config.swift
//  Mova
//
//  Created by Serhii on 02.10.2023.
//

import Foundation

struct Config {
    static var productIdentifiers: [String: String] = [:]

    static func loadProductsFromPlist() {
        if let url = Bundle.main.url(forResource: "Products", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: String] {
            productIdentifiers = plist
        } else {
            print("Error loading products from Products.plist")
        }
    }
}
