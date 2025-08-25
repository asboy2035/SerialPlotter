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
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Plot")
                }
                .tag(0)
            
            LogView(networkManager: networkManager)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Log")
                }
                .tag(1)
            
            ConnectionInfoView(networkManager: networkManager)
                .tabItem {
                    Image(systemName: "wifi")
                    Text("Connection")
                }
                .tag(2)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Image(systemName: "wifi")
                        .foregroundColor(.green)
                    Text("Connected")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        networkManager.sendCommand(.clearData)
                    }) {
                        Image(systemName: "trash")
                    }
                    
                    Button(action: {
                        if networkManager.isRunning {
                            networkManager.sendCommand(.stopMonitoring)
                        } else {
                            networkManager.sendCommand(.startMonitoring)
                        }
                    }) {
                        Image(systemName: networkManager.isRunning ? "stop.fill" : "play.fill")
                    }
                    .foregroundColor(networkManager.isRunning ? .red : .green)
                }
            }
        }
    }
}
