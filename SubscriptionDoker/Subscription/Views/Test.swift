//
//  Test.swift
//  SubscriptionDoker
//
//  Created by Serhii on 03.10.2024.
//

import SwiftUI
import StoreKit

struct Test: View {

  var body: some View {
//      SubscriptionStoreView(groupID: "0BB057E9")
      SubscriptionStoreView(groupID: "21551379")
      .subscriptionStoreControlStyle(.automatic, placement: .automatic)
    }

}

#Preview {
    Test()
}
