//
//  ConnectionView.swift
//  SerialBridge
//
//  Created by ash on 8/25/25.
//

import SwiftUI

struct ConnectionView: View {
    @ObservedObject var networkManager: MobileNetworkManager
    @State private var showingScanner = false
    @State private var manualHost = ""
    @State private var manualPort = "8080"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Button(action: {
                        showingScanner = true
                    }) {
                        Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .tint(.accentColor)
                    .clipShape(.capsule)
                    .modifier(GlassEffectIfAvailable())
                    
                    Text("or")
                        .foregroundStyle(.secondary)
                    
                    Form {
                        Section(header: Text("Manual Connection")) {
                            HStack {
                                Text("Host:")
                                    .frame(width: 60, alignment: .leading)
                                
                                TextField("192.168.1.100", text: $manualHost)
                            }

                            HStack {
                                Text("Port:")
                                    .frame(width: 60, alignment: .leading)
                                
                                TextField("8080", text: $manualPort)
                                    .keyboardType(.numberPad)
                            }
                        }
                    }
                    
                    Button(action: {
                        if let port = UInt16(manualPort) {
                            networkManager.connectToDesktop(host: manualHost, port: port)
                        }
                    }) {
                        Label("Connect Manually", systemImage: "cable.connector.horizontal")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .tint(manualHost.isEmpty ? Color.secondary : Color.accentColor)
                    .clipShape(.capsule)
                    .modifier(GlassEffectIfAvailable())
                    .disabled(manualHost.isEmpty)
                }
                
                if networkManager.isConnecting {
                    VStack {
                        ProgressView()
                        Text("Connecting...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = networkManager.connectionError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.red.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Connect")
            .modifier(NavigationSubtitleIfAvailable(subtitle: "SerialBridge"))
            .sheet(isPresented: $showingScanner) {
                QRScannerView { result in
                    showingScanner = false
                    networkManager.handleQRCode(result)
                }
            }
        }
    }
}
