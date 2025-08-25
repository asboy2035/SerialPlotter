//
//  DeviceMonitorManager.swift
//  SerialPlotter
//
//  Created by ash on 8/17/25.
//

import Combine
import Foundation
import DynamicNotchKit
internal import System
import SwiftUI

class DeviceMonitorManager: ObservableObject {
    private var currentNotch: DynamicNotchInfo?
    private var currentNotchDescription: String? = nil
    private var lastValues: [String: Double] = [:]
    @Published var readings: [DeviceReading] = []
    @Published var outputLines: [String] = []
    @Published var isRunning = false
    @Published var workingDirectory: String {
        didSet {
            UserDefaults.standard.set(workingDirectory, forKey: "workingDirectory")
        }
    }
    @Published var device = "megaatmega2560"
    
    var networkManager: NetworkManager?

    private var task: Process?
    private var pipe: Pipe?
    private var outputBuffer = ""  // Buffer to accumulate partial lines
    private let outputQueue = DispatchQueue(label: "com.serialplotter.output", qos: .userInitiated)

    init() {
        // Load the saved working directory, or default to the home directory
        self.workingDirectory = UserDefaults.standard.string(forKey: "workingDirectory") ?? NSHomeDirectory()
        
        // Listen for remote commands
        NotificationCenter.default.addObserver(
            forName: .remoteCommand,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let command = notification.object as? NetworkCommand {
                self?.handleRemoteCommand(command)
            }
        }
    }
    
    private func handleRemoteCommand(_ command: NetworkCommand) {
        switch command {
        case .startMonitoring:
            if !isRunning {
                startMonitoring()
            }
        case .stopMonitoring:
            if isRunning {
                stopMonitoring()
            }
        case .clearData:
            clearData()
        }
    }

    func startMonitoring() {
        stopMonitoring() // Stop any existing monitoring

        isRunning = true
        outputLines.append("🚀 Starting monitoring...")
        
        // Send sync data to mobile when monitoring starts
        networkManager?.sendFullSync(readings: readings, logLines: outputLines, isRunning: isRunning)

        task = Process()
        pipe = Pipe()
        
        task?.executableURL = URL(fileURLWithPath: "/bin/zsh")
        if let exeURL = Bundle.main.url(forResource: "SerialMonitor", withExtension: nil) {
            task?.executableURL = exeURL
            task?.arguments = [device]
            task?.standardOutput = pipe
            task?.standardError = pipe
            task?.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/opt/homebrew/Cellar/platformio/6.1.16_3/libexec/bin"
            task?.environment = env
        } else {
            outputLines.append("⚠️ Error: SerialMonitor executable not found in bundle")
            isRunning = false
            networkManager?.sendCommand(.stopMonitoring)
            return
        }
        task?.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        task?.environment = ProcessInfo.processInfo.environment

        // Read output continuously
        pipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                if let output = String(data: data, encoding: .utf8) {
                    // Use a serial queue to ensure thread-safe buffer management
                    self?.outputQueue.async { [weak self] in
                        self?.processOutputSynchronously(output)
                    }
                }
            }
        }

        do {
            try task?.run()
        } catch {
            DispatchQueue.main.async {
                self.outputLines.append("⚠️ Error starting command: \(error.localizedDescription)")
                self.isRunning = false
                self.networkManager?.sendFullSync(readings: self.readings, logLines: self.outputLines, isRunning: self.isRunning)
            }
        }
    }

    func stopMonitoring() {
        task?.terminate()
        pipe?.fileHandleForReading.readabilityHandler = nil
        task = nil
        pipe = nil
        isRunning = false
        outputLines.append("ℹ️ Monitoring stopped")
        
        // Send sync data to mobile when monitoring stops
        networkManager?.sendFullSync(readings: readings, logLines: outputLines, isRunning: isRunning)
    }

    func clearData() {
        readings.removeAll()
        outputLines.removeAll()
        outputBuffer = ""  // Clear the buffer too
        currentNotch = nil  // Clear current notification
        currentNotchDescription = nil
        lastValues.removeAll()  // Clear last values
        outputLines.append("🗑️ Data cleared")
        
        // Send sync data to mobile when data is cleared
        networkManager?.sendFullSync(readings: readings, logLines: outputLines, isRunning: isRunning)
    }

    private func processOutputSynchronously(_ output: String) {
        // This runs on a serial queue to ensure thread safety
        
        // Add new output to our buffer
        outputBuffer += output

        // Split by newlines, but keep the last part (which might be incomplete)
        let components = outputBuffer.components(separatedBy: .newlines)

        // Process all complete lines (all but the last component)
        let completedLines = Array(components.dropLast())
        
        // Keep the last component as our new buffer (it might be a partial line)
        outputBuffer = components.last ?? ""

        // Process completed lines on main queue
        if !completedLines.isEmpty {
            DispatchQueue.main.async { [weak self] in
                Task { [weak self] in
                    for line in completedLines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                        if !trimmedLine.isEmpty {
                            self?.outputLines.append(trimmedLine)
                            await self?.parseDataLine(trimmedLine)
                            
                            // Send log line to network manager
                            self?.networkManager?.sendLogLine(trimmedLine)
                        }
                    }
                    
                    // Keep only recent output lines to prevent memory issues
                    if let self = self, self.outputLines.count > 500 {
                        self.outputLines = Array(self.outputLines.suffix(400))
                    }
                }
            }
        }
    }

    private func parseDataLine(_ line: String) async {
        // Parse lines like: "Slayness: 255 | Iconicness: 4595"
        let components = line.components(separatedBy: " | ")
        var values: [String: Double] = [:]

        for component in components {
            let parts = component.components(separatedBy: ": ")
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                if let value = Double(parts[1].trimmingCharacters(in: .whitespaces)) {
                    values[key] = value
                }
            }
        }

        if !values.isEmpty {
            let reading = DeviceReading(timestamp: Date(), values: values)
            readings.append(reading)
            
            // Send reading to network manager
            networkManager?.sendReading(reading)

            // Activation Alert logic
            let activatedKeys = values.compactMap { (key, value) in
                value == 1 ? key : nil
            }.sorted() // Sort for consistent comparison
            
            if !activatedKeys.isEmpty {
                let newDescription = activatedKeys.joined(separator: ", ") + " are active"
                
                // Only show notification if it's different from current one
                if currentNotchDescription != newDescription {
                    // Hide current notch if it exists
                    if let existingNotch = currentNotch {
                        Task {
                            await existingNotch.hide()
                        }
                    }
                    
                    let notch = DynamicNotchInfo(
                        icon: .init(systemName: "dot.radiowaves.up.forward"),
                        title: "Active Sensors",
                        description: LocalizedStringKey(newDescription)
                    )
                    
                    currentNotch = notch
                    currentNotchDescription = newDescription
                    await notch.expand()
                    hideNotchAfterDelay(notch, delay: 5)
                }
            } else if currentNotch != nil {
                // No active keys, hide current notification
                if let existingNotch = currentNotch {
                    Task {
                        await existingNotch.hide()
                    }
                }
                currentNotch = nil
                currentNotchDescription = nil
            }

            if readings.count > 1000 {
                readings = Array(readings.suffix(800))
            }
        }
    }
    
    private func hideNotchAfterDelay(_ notch: DynamicNotchInfo, delay: TimeInterval) {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            // Only hide if this is still the current notch
            if currentNotch === notch {
                await notch.hide()
                currentNotch = nil
                currentNotchDescription = nil
            }
        }
    }
}
