//
//  ContentView.swift
//  SubscriptionDoker
//
//  Created by Serhii on 03.10.2024.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SubscriptionListView()
                .tabItem {
                    Label("Подписки", systemImage: "cart")
                }
            
            ActiveSubscriptionView()
                .tabItem {
                    Label("Мои подписки", systemImage: "checkmark.circle")
                }
        }
    }
}

