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
        if #available(iOS 26.0, visionOS 26.0, *) {
            TabView {
                Tab {
                    PlotView(networkManager: networkManager)
                } label: {
                    Label("Plot", systemImage: "chart.bar")
                }
                
                Tab {
                    LogView(networkManager: networkManager)
                } label: {
                    Label("Log", systemImage: "list.bullet")
                }
                
                Tab {
                    ConnectionInfoView(networkManager: networkManager)
                } label: {
                    Label("Sync", systemImage: "macbook.and.iphone")
                }
                
                Tab(role: .search) {
                    NavigationStack {
                        SearchView(networkManager: networkManager)
                    }
                }
            }
        } else {
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
                    Image(systemName: "macbook.and.iphone")
                    Text("Sync")
                }
                .tag(2)
        }
    }
}
