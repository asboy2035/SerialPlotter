//
//  ContentView.swift
//  SerialPlotter
//
//  Created by ash on 8/17/25.
//

import Combine
import SwiftUI
import Charts
import Foundation

// Main ContentView
struct ContentView: View {
    @StateObject private var monitorManager = DeviceMonitorManager()
    @State var showingLog = false
    
    private let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {}
                .frame(height: 1)
                .background(
                    VisualEffectView(
                        material: .menu,
                        blendingMode: .behindWindow
                    ).ignoresSafeArea()
                )
            
            VStack {
                // Input Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Command Configuration")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Project Directory:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Path to your project directory", text: $monitorManager.workingDirectory)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: {
                                selectDirectory()
                            }) {
                                Label("Select...", systemImage: "folder")
                            }
                            .help("Select directory")
                        }
                        
                        HStack {
                            Text("Command:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Full path to command", text: $monitorManager.command)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial.opacity(0.1))
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
                .cornerRadius(18)
                .padding(.horizontal)
                
                // Current Values
                if let lastReading = monitorManager.readings.last {
                    let keys = lastReading.values.keys.sorted()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(keys.enumerated()), id: \.element) {
                                index, key in
                                if let value = lastReading.values[key] {
                                    StatusCard(title: key, value: value, color: rainbowColors[index % rainbowColors.count])
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Charts Section
                if !monitorManager.readings.isEmpty {
                    let keys = monitorManager.readings.last?.values.keys.sorted() ?? []
                    TabView {
                        ForEach(Array(keys.enumerated()), id: \.element) {
                            index, key in
                            VStack {
                                Text("\(key) Over Time")
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                
                                Chart(monitorManager.readings.suffix(50)) { reading in
                                    if let value = reading.values[key] {
                                        if value == 0.0 || value == 1.0 {
                                            BarMark(
                                                x: .value("Time", reading.timestamp),
                                                y: .value(key, value)
                                            )
                                            .foregroundStyle(rainbowColors[index % rainbowColors.count])
                                        } else {
                                            LineMark(
                                                x: .value("Time", reading.timestamp),
                                                y: .value(key, value)
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
                            .tabItem {
                                Text(key)
                            }
                        }
                    }
                    .padding()
                } else {
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 50))
                        Text("No data yet")
                            .font(.headline)
                        Text("Start monitoring to see real-time charts")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 0, maxHeight: .infinity)
                }
                
                // Output Log (bottom section)
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
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 1)
                                            .id(index)
                                    }
                                }
                            }
                            .frame(height: 150)
                            .background(.ultraThinMaterial)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
                            .cornerRadius(18)
                            .onChange(of: monitorManager.outputLines.count) { _ in
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
            .toolbar {
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
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                }
            }
            .frame(minWidth: 800, minHeight: 600)
            .background(
                VisualEffectView(
                    material: .menu,
                    blendingMode: .behindWindow
                ).ignoresSafeArea()
            )
        }
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
}

#Preview {
    ContentView()
}