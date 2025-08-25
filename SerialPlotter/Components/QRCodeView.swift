//
//  QRCodeView.swift
//  SerialPlotter
//
//  Created by ash on 8/25/25.
//

import SwiftUI

struct QRCodeView: View {
    @ObservedObject var networkManager: NetworkManager
    
    var body: some View {
        VStack(spacing: 20) {
            if networkManager.isConnected {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Connected!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Your mobile device is now connected and receiving data.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 15) {
                    Text("Scan QR Code")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let qrImage = networkManager.qrCodeImage {
                        Image(nsImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .background(.white)
                            .cornerRadius(10)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.gray.opacity(0.3))
                            .frame(width: 200, height: 200)
                            .overlay {
                                ProgressView()
                            }
                    }
                    
                    Text("Point your mobile device's camera at this QR code")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if let ipAddress = networkManager.serverAddress {
                        Text("Server: \(ipAddress):\(networkManager.serverPort)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}
