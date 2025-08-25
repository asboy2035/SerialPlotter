//
//  ContentView.swift
//  SerialBridge Mobile
//
//  Created by ash on 8/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var mobileNetworkManager = MobileNetworkManager()
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if mobileNetworkManager.isConnected {
                ConnectedView(networkManager: mobileNetworkManager, selectedTab: $selectedTab)
            } else {
                ConnectionView(networkManager: mobileNetworkManager)
            }
        }
    }
}

#Preview {
    ContentView()
}
