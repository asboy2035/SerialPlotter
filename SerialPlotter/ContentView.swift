//
//  ContentView.swift
//  SerialPlotter
//
//  Created by ash on 8/17/25.
//

import Combine
import SwiftUI
import Charts
import DynamicNotchKit
import Foundation
import Network

// Main ContentView
struct ContentView: View {
    @StateObject private var monitorManager = DeviceMonitorManager()
    @StateObject private var networkManager = NetworkManager()
    @State private var showingLog = false
    @State private var selectedKey: String? = nil
    @State private var showingConnectionSheet = false
    @State private var showingQRCode = false
    
    private let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
    private let devicePresets = ["megaatmega2560", "uno", "nano", "esp32"]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {}
                .frame(height: 1)
                .background(
                    VisualEffectView(
                        material: .headerView,
                        blendingMode: .behindWindow
                    ).ignoresSafeArea()
                )
            
            VStack {
                currentValuesSection
                chartsSection
                outputLogSection
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        showingConnectionSheet = true
                    }) {
                        HStack {
                            Image(systemName: networkManager.isConnected ? "wifi" : "wifi.slash")
                                .foregroundStyle(networkManager.isConnected ? .teal : .secondary)
                            Text("Mobile")
                        }
                    }
                }
                
                ToolbarItem {
                    Button(action: {
                        monitorManager.clearData()
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                }
                
                ToolbarItem {
                    Button(action: {
                        if monitorManager.isRunning {
                            monitorManager.stopMonitoring()
                        } else {
                            monitorManager.startMonitoring()
                        }
                    }) {
                        Label(
                            monitorManager.isRunning ? "Stop" : "Start",
                            systemImage: monitorManager.isRunning ? "stop.fill" : "play.fill"
                        )
                    }
                    .keyboardShortcut(
                        monitorManager.isRunning ? "c" : "r",
                        modifiers: monitorManager.isRunning ? .control : .command
                    )
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                }
            }
            .navigationTitle("SerialPlotter")
            .modifier(NavigationSubtitleIfAvailable(subtitle: monitorManager.isRunning ? "Running" : "Press ▶︎ to start."))
            .frame(minWidth: 1000, minHeight: 600)
            .background(
                VisualEffectView(
                    material: .headerView,
                    blendingMode: .behindWindow
                ).ignoresSafeArea()
            )
        }
        .onAppear {
            monitorManager.networkManager = networkManager
            networkManager.syncDataSource = monitorManager
        }
        .sheet(isPresented: $showingConnectionSheet) {
            ConnectionSetupSheet(
                networkManager: networkManager,
                showingQRCode: $showingQRCode
            )
        }
    }

    private var currentValuesSection: some View {
        Group {
            if let lastReading = monitorManager.readings.last {
                let keys = lastReading.values.keys.sorted()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(keys.enumerated()), id: \.element) {
                            index, key in
                            if let value = lastReading.values[key] {
                                StatusCard(title: key, value: value, color: rainbowColors[index % rainbowColors.count], selected: selectedKey == key)
                                    .onTapGesture {
                                        self.selectedKey = key
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: monitorManager.readings.count) {
                    // if we don't have a selected key yet, select the first one
                    if selectedKey == nil {
                        selectedKey = monitorManager.readings.last?.values.keys.sorted().first
                    }
                }
            }
        }
    }

    private var chartsSection: some View {
        Group {
            if !monitorManager.readings.isEmpty {
                if let selectedKey = selectedKey, let index = monitorManager.readings.last?.values.keys.sorted().firstIndex(of: selectedKey) {
                    VStack {
                        Text("\(selectedKey) Over Time")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Chart(monitorManager.readings.suffix(50)) { reading in
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
                        .frame(minHeight: 0, maxHeight: .infinity)
                    }
                    .padding()
                }
            } else {
                PlaceholderItem(
                    systemImage: "chart.bar",
                    systemImageColor: Color.accent,
                    title: "No Data Yet",
                    subtitle: "Start monitoring to see real-time charts."
                )
            }
        }
    }

    private var outputLogSection: some View {
        VStack(alignment: .leading) {
            Button(action: {
                showingLog.toggle()
            }) {
                HStack {
                    Image(systemName: showingLog ? "chevron.down" : "chevron.forward")
                    Text("Log")
                        .font(.headline)
                    Spacer()
                    
                    
                    Text("\(monitorManager.readings.count) readings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(action: {
                        let text = monitorManager.outputLines.joined(separator: "\n")
                        copyToClipboard(text)
                    }) {
                        Label("Copy", systemImage: "document.on.document")
                    }
                    .clipShape(.capsule)
                }
            }
            .buttonStyle(.plain)
            
            if showingLog {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(monitorManager.outputLines.suffix(100).enumerated()), id: \.offset) {
                                index, line in
                                Text(line)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.vertical, 1)
                                    .id(index)
                            }
                        }
                    }
                    .padding()
                    .frame(height: 175)
                    .background(.ultraThinMaterial)
                    .modifier(GlassEffectIfAvailable(radius: 16))
                    .cornerRadius(16)
                    .onChange(of: monitorManager.outputLines.count) {
                        withAnimation {
                            proxy.scrollTo(monitorManager.outputLines.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                monitorManager.workingDirectory = url.path
            }
        }
    }
    
    private func copyToClipboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}

#Preview {
    ContentView()
}
