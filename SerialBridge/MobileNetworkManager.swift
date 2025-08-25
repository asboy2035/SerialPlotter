//
//  MobileNetworkManager.swift
//  SerialBridge Mobile
//
//  Created by ash on 8/25/25.
//

import Foundation
import Network
import SwiftUI
import Combine

class MobileNetworkManager: ObservableObject {
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var connectionError: String?
    @Published var readings: [DeviceReading] = []
    @Published var logLines: [String] = []
    @Published var isRunning = false
    
    var connectedHost: String?
    var connectedPort: UInt16 = 0
    
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "MobileNetworkManager")
    
    func connectToDesktop(host: String, port: UInt16) {
        guard !isConnecting else { return }
        
        disconnect() // Disconnect any existing connection
        
        DispatchQueue.main.async {
            self.isConnecting = true
            self.connectionError = nil
        }
        
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port))
        connection = NWConnection(to: endpoint, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isConnected = true
                    self?.isConnecting = false
                    self?.connectedHost = host
                    self?.connectedPort = port
                    self?.connectionError = nil
                    print("Connected to desktop")
                    
                case .failed(let error):
                    self?.isConnected = false
                    self?.isConnecting = false
                    self?.connectionError = "Connection failed: \(error.localizedDescription)"
                    self?.connection = nil
                    print("Connection failed: \(error)")
                    
                case .cancelled:
                    self?.isConnected = false
                    self?.isConnecting = false
                    self?.connection = nil
                    print("Connection cancelled")
                    
                case .waiting(let error):
                    self?.connectionError = "Waiting: \(error.localizedDescription)"
                    print("Connection waiting: \(error)")
                    
                default:
                    break
                }
            }
        }
        
        connection?.start(queue: queue)
        
        // Start receiving data
        receiveData()
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.isConnecting = false
            self.connectedHost = nil
            self.connectedPort = 0
            self.connectionError = nil
            self.readings.removeAll()
            self.logLines.removeAll()
            self.isRunning = false
        }
        
        print("Disconnected from desktop")
    }
    
    func handleQRCode(_ qrCode: String) {
        // Parse QR code: serialbridge://connect?host=192.168.1.100&port=8080
        guard let url = URL(string: qrCode),
              url.scheme == "serialbridge",
              url.host == "connect",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            DispatchQueue.main.async {
                self.connectionError = "Invalid QR code format"
            }
            return
        }
        
        var host: String?
        var port: UInt16?
        
        for item in queryItems {
            switch item.name {
            case "host":
                host = item.value
            case "port":
                if let portString = item.value {
                    port = UInt16(portString)
                }
            default:
                break
            }
        }
        
        guard let host = host, let port = port else {
            DispatchQueue.main.async {
                self.connectionError = "Missing host or port in QR code"
            }
            return
        }
        
        connectToDesktop(host: host, port: port)
    }
    
    private func receiveData() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.handleReceivedData(data)
            }
            
            if let error = error {
                print("Receive error: \(error)")
                DispatchQueue.main.async {
                    self?.connectionError = "Receive error: \(error.localizedDescription)"
                }
                return
            }
            
            if !isComplete {
                self?.receiveData()
            }
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        do {
            let message = try JSONDecoder().decode(NetworkMessage.self, from: data)
            
            DispatchQueue.main.async {
                switch message.type {
                case .reading:
                    if let readingData = message.data,
                       let reading = try? JSONDecoder().decode(DeviceReading.self, from: readingData) {
                        self.readings.append(reading)
                        
                        // Keep only recent readings to prevent memory issues
                        if self.readings.count > 1000 {
                            self.readings = Array(self.readings.suffix(800))
                        }
                    }
                    
                case .log:
                    if let logData = message.data,
                       let logLine = String(data: logData, encoding: .utf8) {
                        self.logLines.append(logLine)
                        
                        // Keep only recent log lines to prevent memory issues
                        if self.logLines.count > 500 {
                            self.logLines = Array(self.logLines.suffix(400))
                        }
                    }
                    
                case .command:
                    if let commandData = message.data,
                       let command = try? JSONDecoder().decode(NetworkCommand.self, from: commandData) {
                        self.handleDesktopCommand(command)
                    }
                    
                case .status:
                    if let statusData = message.data,
                       let status = try? JSONDecoder().decode(StatusData.self, from: statusData) {
                        self.isRunning = status.isRunning
                    }
                    
                case .sync:
                    if let syncData = message.data,
                       let sync = try? JSONDecoder().decode(SyncData.self, from: syncData) {
                        self.readings = sync.readings
                        self.logLines = sync.logLines
                        self.isRunning = sync.isRunning
                    }
                }
            }
        } catch {
            print("Failed to decode received message: \(error)")
        }
    }
    
    private func handleDesktopCommand(_ command: NetworkCommand) {
        switch command {
        case .startMonitoring:
            isRunning = true
        case .stopMonitoring:
            isRunning = false
        case .clearData:
            readings.removeAll()
            logLines.removeAll()
        }
    }
    
    func sendCommand(_ command: NetworkCommand) {
        guard let connection = connection, isConnected else { return }
        
        do {
            let commandData = try JSONEncoder().encode(command)
            let message = NetworkMessage(type: .command, data: commandData)
            let messageData = try JSONEncoder().encode(message)
            
            connection.send(content: messageData, completion: .contentProcessed { error in
                if let error = error {
                    print("Send command error: \(error)")
                }
            })
            
            // Update local state optimistically
            DispatchQueue.main.async {
                switch command {
                case .startMonitoring:
                    self.isRunning = true
                case .stopMonitoring:
                    self.isRunning = false
                case .clearData:
                    self.readings.removeAll()
                    self.logLines.removeAll()
                }
            }
            
        } catch {
            print("Failed to encode command: \(error)")
        }
    }
}
