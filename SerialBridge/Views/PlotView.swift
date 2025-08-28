//
//  PlotView.swift
//  SerialBridge
//
//  Created by ash on 8/25/25.
//

import SwiftUI
import Charts

struct PlotView: View {
    @ObservedObject var networkManager: MobileNetworkManager
    @State private var selectedKey: String?
    
    private let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                currentValuesSection
                chartsSection
            }
            .navigationTitle("Plot")
            .modifier(NavigationSubtitleIfAvailable(subtitle: "Streaming"))
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
        }
    }
    
    private var currentValuesSection: some View {
        Group {
            if let lastReading = networkManager.readings.last {
                let keys = lastReading.values.keys.sorted()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(keys.enumerated()), id: \.element) { index, key in
                            if let value = lastReading.values[key] {
                                StatusCard(
                                    title: key,
                                    value: value,
                                    color: rainbowColors[index % rainbowColors.count],
                                    selected: selectedKey == key
                                )
                                .onTapGesture {
                                    selectedKey = key
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: networkManager.readings.count) { _ in
                    if selectedKey == nil {
                        selectedKey = networkManager.readings.last?.values.keys.sorted().first
                    }
                }
            }
        }
    }
    
    private var chartsSection: some View {
        VStack {
            if !networkManager.readings.isEmpty {
                if let selectedKey = selectedKey,
                   let index = networkManager.readings.last?.values.keys.sorted().firstIndex(of: selectedKey) {
                    VStack {
                        Text("\(selectedKey) Over Time")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Chart(networkManager.readings.suffix(30)) { reading in
                            if let value = reading.values[selectedKey] {
                                if value == 0.0 || value == 1.0 {
                                    BarMark(
                                        x: .value("Time", reading.timestamp),
                                        y: .value(selectedKey, value)
                                    )
                                    .foregroundStyle(rainbowColors[index % rainbowColors.count])
                                } else {
                                    LineMark(
                                        x: .value("Time", reading.timestamp),
                                        y: .value(selectedKey, value)
                                    )
                                    .foregroundStyle(rainbowColors[index % rainbowColors.count])
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel(format: .dateTime.hour().minute())
                            }
                        }
                        .frame(height: 250)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .frame(minHeight: 0, maxHeight: .infinity)
                }
            } else {
                PlaceholderItem(
                    systemImage: "chart.bar",
                    systemImageColor: Color.accent,
                    title: "No Data Yet",
                    subtitle: "Start monitoring on desktop to see charts."
                )
            }
        }
    }
}
