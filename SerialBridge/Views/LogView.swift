//
//  LogView.swift
//  SerialBridge
//
//  Created by ash on 8/25/25.
//

import SwiftUI

struct LogView: View {
    @ObservedObject var networkManager: MobileNetworkManager
    
    var body: some View {
        NavigationView {
            VStack {
                if networkManager.logLines.isEmpty {
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                        Text("No logs yet")
                            .font(.headline)
                        Text("Start monitoring to see logs")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 2) {
                                ForEach(Array(networkManager.logLines.enumerated()), id: \.offset) { index, line in
                                    Text(line)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(.vertical, 1)
                                        .id(index)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: networkManager.logLines.count) { _ in
                            withAnimation {
                                proxy.scrollTo(networkManager.logLines.count - 1, anchor: .bottom)
                            }
                        }
                    }
                }
                
                HStack {
                    Text("\(networkManager.readings.count) readings")
                    Spacer()
                    Text("\(networkManager.logLines.count) log lines")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
            }
            .navigationTitle("Log")
            .modifier(NavigationSubtitleIfAvailable(subtitle: "Streaming"))
        }
    }
}
