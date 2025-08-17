//
//  DeviceMonitorManager.swift
//  SerialPlotter
//
//  Created by ash on 8/17/25.
//

import Combine
import Foundation


class DeviceMonitorManager: ObservableObject {
    @Published var readings: [DeviceReading] = []
    @Published var outputLines: [String] = []
    @Published var isRunning = false
    @Published var workingDirectory = "/Users/ash/your-project-directory"
    @Published var command = "/Users/ash/.platformio/penv/bin/pio device monitor -e megaatmega2560"
    
    private var task: Process?
    private var pipe: Pipe?
    private var outputBuffer = ""  // Buffer to accumulate partial lines
    
    func startMonitoring() {
        stopMonitoring() // Stop any existing monitoring
        
        isRunning = true
        outputLines.append("🚀 Starting monitoring...")
        
        task = Process()
        pipe = Pipe()
        
        task?.standardOutput = pipe
        task?.standardError = pipe
        task?.launchPath = "/bin/bash"
        task?.arguments = ["-c", "cd '\(workingDirectory)' && \(command)"]
        
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
        // Parse lines like: "Charging Rate: 36 | New Charge: 0.06 | Battery: 5.00 | Charging: 1 | Light: Off | Dimmer: 63"
        let components = line.components(separatedBy: " | ")
        
        var chargingRate: Double?
        var newCharge: Double?
        var battery: Double?
        var charging: Bool?
        var dimmer: Double?
        
        for component in components {
            let parts = component.components(separatedBy: ": ")
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let valueString = parts[1].trimmingCharacters(in: .whitespaces)
                
                switch key {
                case "Charging Rate":
                    chargingRate = Double(valueString)
                case "New Charge":
                    newCharge = Double(valueString)
                case "Battery":
                    battery = Double(valueString)
                case "Charging":
                    charging = valueString == "1"
                case "Dimmer":
                    dimmer = Double(valueString)
                default:
                    break
                }
            }
        }
        
        // Only create a reading if we have the essential data
        if let chargingRate = chargingRate,
           let newCharge = newCharge,
           let battery = battery,
           let charging = charging,
           let dimmer = dimmer {
            
            let reading = DeviceReading(
                timestamp: Date(),
                chargingRate: chargingRate,
                newCharge: newCharge,
                battery: battery,
                charging: charging,
                dimmer: dimmer
            )
            
            readings.append(reading)
            
            // Keep only recent readings to prevent memory issues
            if readings.count > 1000 {
                readings = Array(readings.suffix(800))
            }
        }
    }
}
