//
//  NetworkManager.swift
//  SerialBridge
//
//  Created by ash on 8/25/25.
//

import Foundation
import Network
import SwiftUI
import CoreImage.CIFilterBuiltins
import AppKit
import Combine

struct DeviceReading: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let values: [String: Double]
}

enum NetworkCommand: String, Codable {
    case startMonitoring = "start"
    case stopMonitoring = "stop"
    case clearData = "clear"
}

struct NetworkMessage: Codable {
    enum MessageType: String, Codable {
        case reading = "reading"
        case log = "log"
        case command = "command"
        case status = "status"
        case sync = "sync"
    }
    
    let type: MessageType
    let timestamp: Date
    let data: Data?
    
    init(type: MessageType, data: Data? = nil) {
        self.type = type
        self.timestamp = Date()
        self.data = data
    }
}

struct StatusData: Codable {
    let isRunning: Bool
    let readingsCount: Int
    let logLinesCount: Int
}

struct SyncData: Codable {
    let readings: [DeviceReading]
    let logLines: [String]
    let isRunning: Bool
}

class NetworkManager: ObservableObject {
    @Published var isConnected = false
    @Published var serverAddress: String?
    @Published var qrCodeImage: NSImage?
    
    let serverPort: UInt16 = 8080
    private var listener: NWListener?
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "NetworkManager")
    
    func startServer() {
        guard listener == nil else { return }
        
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: serverPort))
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.start(queue: queue)
            
            // Get the local IP address
            DispatchQueue.main.async {
                self.serverAddress = self.getLocalIPAddress()
                self.generateQRCode()
            }
            
            print("Server started on port \(serverPort)")
        } catch {
            print("Failed to start server: \(error)")
        }
    }
    
    func stopServer() {
        listener?.cancel()
        listener = nil
        connection?.cancel()
        connection = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.serverAddress = nil
            self.qrCodeImage = nil
        }
        
        print("Server stopped")
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        print("New connection received")
        
        self.connection = connection
        
        connection.start(queue: queue)
        
        DispatchQueue.main.async {
            self.isConnected = true
        }
        
        // Send initial sync data
        sendSyncData()
        
        // Start receiving data
        receiveData(on: connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Connection ready")
            case .cancelled, .failed:
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
                print("Connection ended")
            default:
                break
            }
        }
    }
    
    private func receiveData(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.handleReceivedData(data)
            }
            
            if let error = error {
                print("Receive error: \(error)")
                return
            }
            
            if !isComplete {
                self?.receiveData(on: connection)
            }
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        do {
            let message = try JSONDecoder().decode(NetworkMessage.self, from: data)
            
            switch message.type {
            case .command:
                if let commandData = message.data,
                   let command = try? JSONDecoder().decode(NetworkCommand.self, from: commandData) {
                    handleRemoteCommand(command)
                }
            default:
                break
            }
        } catch {
            print("Failed to decode received message: \(error)")
        }
    }
    
    private func handleRemoteCommand(_ command: NetworkCommand) {
        DispatchQueue.main.async {
            // These commands would be handled by the DeviceMonitorManager
            // For now, we'll post notifications that the UI can observe
            NotificationCenter.default.post(name: .remoteCommand, object: command)
        }
    }
    
    func sendReading(_ reading: DeviceReading) {
        guard let connection = connection, isConnected else { return }
        
        do {
            let readingData = try JSONEncoder().encode(reading)
            let message = NetworkMessage(type: .reading, data: readingData)
            let messageData = try JSONEncoder().encode(message)
            
            connection.send(content: messageData, completion: .contentProcessed { error in
                if let error = error {
                    print("Send error: \(error)")
                }
            })
        } catch {
            print("Failed to encode reading: \(error)")
        }
    }
    
    func sendLogLine(_ line: String) {
        guard let connection = connection, isConnected else { return }
        
        do {
            let logData = line.data(using: .utf8)
            let message = NetworkMessage(type: .log, data: logData)
            let messageData = try JSONEncoder().encode(message)
            
            connection.send(content: messageData, completion: .contentProcessed { error in
                if let error = error {
                    print("Send error: \(error)")
                }
            })
        } catch {
            print("Failed to encode log line: \(error)")
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
                    print("Send error: \(error)")
                }
            })
        } catch {
            print("Failed to encode command: \(error)")
        }
    }
    
    private func sendSyncData() {
        // This would be called from DeviceMonitorManager with current state
        // For now, we'll send empty sync data
        guard let connection = connection, isConnected else { return }
        
        let syncData = SyncData(readings: [], logLines: [], isRunning: false)
        
        do {
            let syncDataEncoded = try JSONEncoder().encode(syncData)
            let message = NetworkMessage(type: .sync, data: syncDataEncoded)
            let messageData = try JSONEncoder().encode(message)
            
            connection.send(content: messageData, completion: .contentProcessed { error in
                if let error = error {
                    print("Send sync error: \(error)")
                }
            })
        } catch {
            print("Failed to encode sync data: \(error)")
        }
    }
    
    func sendFullSync(readings: [DeviceReading], logLines: [String], isRunning: Bool) {
        guard let connection = connection, isConnected else { return }
        
        let syncData = SyncData(readings: readings, logLines: logLines, isRunning: isRunning)
        
        do {
            let syncDataEncoded = try JSONEncoder().encode(syncData)
            let message = NetworkMessage(type: .sync, data: syncDataEncoded)
            let messageData = try JSONEncoder().encode(message)
            
            connection.send(content: messageData, completion: .contentProcessed { error in
                if let error = error {
                    print("Send sync error: \(error)")
                }
            })
        } catch {
            print("Failed to encode sync data: \(error)")
        }
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" || name == "en1" { // WiFi or Ethernet
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                                  &hostname, socklen_t(hostname.count),
                                  nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                        if address != "127.0.0.1" {
                            break
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
    
    private func generateQRCode() {
        guard let address = serverAddress else { return }
        
        let connectionString = "serialbridge://connect?host=\(address)&port=\(serverPort)"
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(connectionString.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                DispatchQueue.main.async {
                    self.qrCodeImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                }
            }
        }
    }
}

extension Notification.Name {
    static let remoteCommand = Notification.Name("remoteCommand")
}
