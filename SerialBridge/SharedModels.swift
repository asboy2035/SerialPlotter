//
//  SharedModels.swift
//  SerialBridge
//
//  Created by ash on 8/25/25.
//

import Foundation
import SwiftUI

// MARK: - Status Card (Desktop version)
#if os(macOS)
struct StatusCard: View {
    let title: String
    let value: Double
    let color: Color
    let selected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(String(format: "%.1f", value))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(16)
        .frame(minWidth: 120)
        .background(selected ? color.opacity(0.15) : .ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(selected ? color : .clear, lineWidth: 2)
        )
        .modifier(GlassEffectIfAvailable(radius: 16))
        .cornerRadius(16)
    }
}

// MARK: - Visual Effect View (macOS)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Modifiers (macOS)
struct GlassEffectIfAvailable: ViewModifier {
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        if #available(macOS 12.0, *) {
            content
                .background(.ultraThinMaterial)
                .cornerRadius(radius)
        } else {
            content
                .background(Color.black.opacity(0.1))
                .cornerRadius(radius)
        }
    }
}

struct NavigationSubtitleIfAvailable: ViewModifier {
    let subtitle: String
    
    func body(content: Content) -> some View {
        if #available(macOS 13.0, *) {
            content
                .navigationSubtitle(subtitle)
        } else {
            content
        }
    }
}

#endif

// MARK: - Shared Data Models
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

// MARK: - Extensions
extension Notification.Name {
    static let remoteCommand = Notification.Name("remoteCommand")
}

#if os(macOS)
extension NSApplication {
    func requestUserAttention() {
        NSApp.requestUserAttention(.informationalRequest)
    }
}
#endif
