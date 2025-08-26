//
//  ConnectedView.swift
//  SerialBridge
//
//  Created by ash on 8/25/25.
//

import SwiftUI

struct ConnectedView: View {
    @ObservedObject var networkManager: MobileNetworkManager
    @Binding var selectedTab: Int
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PlotView(networkManager: networkManager)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Plot")
                }
                .tag(0)
            
            LogView(networkManager: networkManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Log")
                }
                .tag(1)
            
            ConnectionInfoView(networkManager: networkManager)
                .tabItem {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                    Text("Sync")
                }
                .tag(2)
        }
    }
}
