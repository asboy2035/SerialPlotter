//
//  NetworkManager.swift
//  SerialPlotter
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
    
    let serverPort: UInt16 = 5050
    
    private var listener: NWListener?
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.serialplotter.network")
    
    init() {
        startListening()
    }
    
    func startListening() {
        guard listener == nil else { return }
        
        do {
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: serverPort) ?? 8080)
            
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        print("Listener ready on port \(self?.serverPort ?? 0)")
                        self?.serverAddress = self?.getLocalIPAddress()
                        self?.generateQRCode()
                    case .failed(let error):
                        print("Listener failed with error: \(error)")
                        self?.isConnected = false
                        self?.listener?.cancel()
                        self?.listener = nil
                    default:
                        break
                    }
                }
            }
            
            listener?.newConnectionHandler = { [weak self] newConnection in
                print("New connection accepted!")
                self?.connection = newConnection
                newConnection.stateUpdateHandler = { [weak self] state in
                    DispatchQueue.main.async {
                        switch state {
                        case .ready:
                            print("Connection is ready!")
                            self?.isConnected = true
                            self?.receiveData()
                            self?.syncMobile()
                        case .failed(let error):
                            print("Connection failed with error: \(error)")
                            self?.isConnected = false
                            self?.connection?.cancel()
                            self?.connection = nil
                        case .cancelled:
                            print("Connection cancelled.")
                            self?.isConnected = false
                            self?.connection = nil
                        default:
                            break
                        }
                    }
                }
                newConnection.start(queue: self?.queue ?? .main)
            }
            
            listener?.start(queue: queue)
        } catch {
            print("Failed to start listener: \(error)")
        }
    }
    
    func stopListening() {
        guard listener != nil else { return }
        
        print("Stopping network listener...")
        listener?.cancel()
        listener = nil
        
        if let connection = connection {
            connection.cancel()
            self.connection = nil
        }
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.qrCodeImage = nil
            self.serverAddress = nil
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
    
    private func receiveData() {
        guard let connection = connection else { return }
        
        connection.receiveMessage { [weak self] (data, context, isComplete, error) in
            if let data = data, !data.isEmpty {
                self?.handleMessage(data)
            }
            
            if let error = error {
                print("Receive error: \(error)")
                self?.isConnected = false
                return
            }
            
            if isComplete {
                print("Message receive complete.")
                self?.isConnected = false
            } else {
                self?.receiveData() // Continue receiving
            }
        }
    }
    
    private func handleMessage(_ data: Data) {
        do {
            let message = try JSONDecoder().decode(NetworkMessage.self, from: data)
            if message.type == .command {
                if let commandData = message.data,
                   let command = try? JSONDecoder().decode(NetworkCommand.self, from: commandData) {
                    print("Received command: \(command.rawValue)")
                    NotificationCenter.default.post(name: .remoteCommand, object: command)
                }
            }
        } catch {
            print("Failed to decode message: \(error)")
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
            let logData = try JSONEncoder().encode(line)
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
    
    private func syncMobile() {
        // Send initial state
        let status = StatusData(isRunning: true, readingsCount: 0, logLinesCount: 0)
        let message = try! JSONEncoder().encode(NetworkMessage(type: .status, data: try! JSONEncoder().encode(status)))
        connection?.send(content: message, completion: .contentProcessed({ _ in }))
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                
                if (interface?.ifa_flags ?? 0) & UInt32(IFF_LOOPBACK) == 0,
                   let addr = interface?.ifa_addr.pointee,
                   addr.sa_family == UInt8(AF_INET) {
                    
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
