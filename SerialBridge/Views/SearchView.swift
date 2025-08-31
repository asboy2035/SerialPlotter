//
//  SearchView.swift
//  SerialBridge
//
//  Created by ash on 8/31/25.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var networkManager: MobileNetworkManager
    @State var searchText: String = ""
    
    var filteredReadings: [DeviceReading] {
        if searchText.isEmpty {
            return networkManager.readings
        } else {
            return networkManager.readings.filter { reading in
                reading.values.keys.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                reading.values.values.contains { "\($0)".localizedCaseInsensitiveContains(searchText) }
            }
        }
    }

    var filteredLogs: [String] {
        if searchText.isEmpty {
            return networkManager.logLines
        } else {
            return networkManager.logLines.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if networkManager.logLines.isEmpty {
                    PlaceholderItem(
                        systemImage: "doc.text",
                        systemImageColor: Color.yellow,
                        title: "No Data Yet",
                        subtitle: "Start monitoring to search data."
                    )
                    .frame(height: 250)
                } else {
                    Section("Values") {
                        if let lastReading = filteredReadings.last {
                            let keys = lastReading.values.keys.sorted()
                            ForEach(Array(keys.enumerated()), id: \.element) { index, key in
                                if let value = lastReading.values[key] {
                                    if searchText.isEmpty ||
                                        key.localizedCaseInsensitiveContains(searchText) ||
                                        "\(value)".localizedCaseInsensitiveContains(searchText) {
                                        VStack(alignment: .leading) {
                                            Text(key)
                                            Text("\(value)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Section("Logs") {
                        ForEach(Array(filteredLogs.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.vertical, 1)
                                .id(index)
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
            .searchable(text: $searchText)
            .navigationTitle("Search")
            .modifier(NavigationSubtitleIfAvailable(subtitle: "Data"))
        }
    }
}
