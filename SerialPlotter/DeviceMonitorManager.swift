//
//  DeviceMonitorManager.swift
//  SerialPlotter
//
//  Created by ash on 8/17/25.
//

import Combine
import Foundation
internal import System

class DeviceMonitorManager: ObservableObject {
    @Published var readings: [DeviceReading] = []
    @Published var outputLines: [String] = []
    @Published var isRunning = false
    @Published var workingDirectory: String {
        didSet {
            UserDefaults.standard.set(workingDirectory, forKey: "workingDirectory")
        }
    }
    @Published var device = "megaatmega2560"

    private var task: Process?
    private var pipe: Pipe?
    private var outputBuffer = ""  // Buffer to accumulate partial lines

    init() {
        // Load the saved working directory, or default to the home directory
        self.workingDirectory = UserDefaults.standard.string(forKey: "workingDirectory") ?? NSHomeDirectory()
    }

    func startMonitoring() {
        stopMonitoring() // Stop any existing monitoring

        isRunning = true
        outputLines.append("🚀 Starting monitoring...")

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
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/opt/homebrew/Cellar/platformio/6.1.18_3/libexec/bin"
            task?.environment = env
        } else {
            outputLines.append("❌ Error: SerialMonitor executable not found in bundle")
            isRunning = false
            return
        }
        task?.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        task?.environment = ProcessInfo.processInfo.environment

        // Read output continuously
        pipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                if let output = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self?.processOutput(output)
                    }
                }
            }
        }

        do {
            try task?.run()
        } catch {
            DispatchQueue.main.async {
                self.outputLines.append("❌ Error starting command: \(error.localizedDescription)")
                self.isRunning = false
            }
        }
    }

    func stopMonitoring() {
        task?.terminate()
        pipe?.fileHandleForReading.readabilityHandler = nil
        task = nil
        pipe = nil
        isRunning = false
        outputLines.append("⏹️ Monitoring stopped")
    }

    func clearData() {
        readings.removeAll()
        outputLines.removeAll()
        outputBuffer = ""  // Clear the buffer too
        outputLines.append("🗑️ Data cleared")
    }

    private func processOutput(_ output: String) {
        // Add new output to our buffer
        outputBuffer += output

        // Split by newlines, but keep the last part (which might be incomplete)
        let components = outputBuffer.components(separatedBy: .newlines)

        // Process all complete lines (all but the last component)
        for i in 0..<(components.count - 1) {
            let line = components[i].trimmingCharacters(in: .whitespaces)
            if !line.isEmpty {
                outputLines.append(line)
                parseDataLine(line)
            }
        }

        // Keep the last component as our new buffer (it might be a partial line)
        outputBuffer = components.last ?? ""

        // Keep only recent output lines to prevent memory issues
        if outputLines.count > 500 {
            outputLines = Array(outputLines.suffix(400))
        }
    }

    private func parseDataLine(_ line: String) {
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

            if readings.count > 1000 {
                readings = Array(readings.suffix(800))
            }
        }
    }
}
