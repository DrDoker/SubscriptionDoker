//
//  ContentView.swift
//  SubscriptionDoker
//
//  Created by Serhii on 02.10.2024.
//

import SwiftUI

struct MainTabView: View {
    @StateObject var purchaseManager = PurchaseManager()
    
    var body: some View {
        TabView {
            MainView()
                .tabItem {
                    Image(systemName: "captions.bubble.fill")
                    Text("Translate")
                }
            
            SubscriptionView()
                .environmentObject(purchaseManager)
                .tabItem {
                    Image(systemName: "circle.grid.2x2.fill")
                    Text("More")
                }
        }
    }
}

#Preview {
    MainTabView()
}
