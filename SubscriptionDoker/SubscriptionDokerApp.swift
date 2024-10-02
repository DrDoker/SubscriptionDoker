//
//  SubscriptionDokerApp.swift
//  SubscriptionDoker
//
//  Created by Serhii on 02.10.2024.
//

import SwiftUI

@main
struct SubscriptionDokerApp: App {
    @StateObject var purchaseManager = PurchaseManager()
    
    var body: some Scene {
        WindowGroup {
            SubscriptionView()
                .environmentObject(purchaseManager)
            
        }
    }
}
