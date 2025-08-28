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
    @State private var showingManualConnection: Bool = false
    @State private var manualHost = ""
    @State private var manualPort = "8080"
    
    var body: some View {
        VStack {
            VStack {
                ConnectionOptionCard(
                    systemImage: "qrcode.viewfinder",
                    systemImageColor: Color.accent,
                    title: "QR Code",
                    subtitle: "Scan QR code from SerialPlotter."
                )
                .onTapGesture {
                    showingScanner = true
                }
                
                Text("or")
                    .foregroundStyle(.secondary)

                ConnectionOptionCard(
                    systemImage: "rectangle.and.pencil.and.ellipsis",
                    systemImageColor: Color.indigo,
                    title: "Manual Entry",
                    subtitle: "Enter host and port manually."
                )
                .onTapGesture {
                    showingManualConnection = true
                }
            }
            
            Spacer()
            if networkManager.isConnecting {
                HStack {
                    ProgressView()
                    Text("Connecting...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical)
            }
            
            if let error = networkManager.connectionError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(18)
                    .background(.red.opacity(0.2))
                    .cornerRadius(22)
            }
        }
        .padding()
        .navigationTitle("Connect")
        .modifier(NavigationSubtitleIfAvailable(subtitle: "SerialBridge"))
        .sheet(isPresented: $showingScanner) {
            QRScannerScreen(
                networkManager: networkManager,
                showingQRCodeScreen: $showingScanner
            )
        }
        .sheet(isPresented: $showingManualConnection) {
            VStack {
                PlaceholderItem(
                    systemImage: "rectangle.and.pencil.and.ellipsis",
                    systemImageColor: Color.indigo,
                    title: "Manual Entry",
                    subtitle: "Enter host and port manually.",
                    isProminent: true
                )
                
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
                Spacer()
                
                HStack {
                    Button(action: {
                        showingManualConnection = false
                    }) {
                        Label("Cancel", systemImage: "xmark")
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .clipShape(.capsule)
                    
                    Spacer()
                    
                    Button(action: {
                        if let port = UInt16(manualPort) {
                            networkManager.connectToDesktop(host: manualHost, port: port)
                        }
                    }) {
                        Label("Connect", systemImage: "cable.connector.horizontal")
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .tint(manualHost.isEmpty ? Color.secondary : Color.accentColor)
                    .clipShape(.capsule)
                    .disabled(manualHost.isEmpty)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ConnectionView(networkManager: MobileNetworkManager())
}
