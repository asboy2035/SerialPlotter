//
//  QRCodeView.swift
//  SerialPlotter
//
//  Created by ash on 8/25/25.
//

import SwiftUI

struct QRCodeView: View {
    @ObservedObject var networkManager: NetworkManager
    @Binding var showingQRCode: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            if networkManager.isConnected {
                PlaceholderItem(
                    systemImage: "checkmark.circle.fill",
                    systemImageColor: Color.teal,
                    title: "Connected",
                    subtitle: "SerialBridge is now connected!",
                    isProminent: true
                )
            } else {
                VStack {
                    PlaceholderItem(
                        systemImage: "qrcode",
                        systemImageColor: Color.yellow,
                        title: "Scan QR Code",
                        subtitle: "Open SerialBridge on your iPhone and scan the QR code:",
                        isProminent: true
                    )
                    
                    if let qrImage = networkManager.qrCodeImage {
                        Image(nsImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 125, height: 125)
                            .background(.white)
                            .cornerRadius(10)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.gray.opacity(0.3))
                            .frame(width: 125, height: 125)
                            .overlay {
                                ProgressView()
                            }
                    }

                    if let ipAddress = networkManager.serverAddress {
                        Text("Server: \(ipAddress):\(networkManager.serverPort)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button {
                    showingQRCode = false
                } label: {
                    Label("Instructions", systemImage: "book.pages")
                        .padding(.vertical, 4)
                }
                .clipShape(.capsule)
            }
        }
    }
}
