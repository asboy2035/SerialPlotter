//
//  ConnectionInfoView.swift
//  SerialBridge
//
//  Created by ash on 8/25/25.
//

import SwiftUI

struct ConnectionInfoView: View {
    @ObservedObject var networkManager: MobileNetworkManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Connection Status") {
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Connected")
                                .font(.headline)
                            if let host = networkManager.connectedHost {
                                Text("\(host):\(networkManager.connectedPort)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                
                Section("Desktop Status") {
                    HStack {
                        Image(systemName: networkManager.isRunning ? "play.fill" : "stop.fill")
                            .foregroundColor(networkManager.isRunning ? .green : .red)
                        Text(networkManager.isRunning ? "Monitoring Active" : "Monitoring Stopped")
                    }
                }
                
                Section("Data") {
                    HStack {
                        Image(systemName: "chart.bar")
                        Text("Readings")
                        Spacer()
                        Text("\(networkManager.readings.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Log Lines")
                        Spacer()
                        Text("\(networkManager.logLines.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Disconnect") {
                        networkManager.disconnect()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Connection")
            .modifier(NavigationSubtitleIfAvailable(subtitle: "Settings and info"))
        }
    }
}
