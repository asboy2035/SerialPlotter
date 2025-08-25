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
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text("Scan QR Code")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Text("or")
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Host:")
                                .frame(width: 60, alignment: .leading)
                            TextField("192.168.1.100", text: $manualHost)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Port:")
                                .frame(width: 60, alignment: .leading)
                            TextField("8080", text: $manualPort)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        Button("Connect Manually") {
                            if let port = UInt16(manualPort) {
                                networkManager.connectToDesktop(host: manualHost, port: port)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(manualHost.isEmpty ? .gray : .green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(manualHost.isEmpty)
                    }
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
                        .cornerRadius(8)
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
