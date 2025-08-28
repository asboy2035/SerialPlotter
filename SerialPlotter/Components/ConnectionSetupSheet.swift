//
//  ConnectionSetupSheet.swift
//  SerialPlotter
//
//  Created by ash on 8/25/25.
//

import SwiftUI

struct ConnectionSetupSheet: View {
    @ObservedObject var networkManager: NetworkManager
    @Binding var showingQRCode: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            if showingQRCode {
                QRCodeView(networkManager: networkManager, showingQRCode: $showingQRCode)
            } else {
                InstructionsView(showingQRCode: $showingQRCode, networkManager: networkManager)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
        .toolbar {
            if !showingQRCode {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        networkManager.startListening()
                        showingQRCode = true
                    } label: {
                        Label("Next", systemImage: "arrow.forward")
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(.capsule)
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Label("Close", systemImage: "xmark")
                        .padding(.vertical, 4)
                }
                .clipShape(.capsule)
            }
            
            if networkManager.isConnected {
                ToolbarItem(placement: .destructiveAction) {
                    Button {
                        networkManager.stopListening()
                        dismiss()
                    } label: {
                        Label("Disconnect", systemImage: "iphone.slash")
                            .padding(.vertical, 4)
                    }
                    .clipShape(.capsule)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var showingQRCode: Bool = false
    
    ConnectionSetupSheet(networkManager: NetworkManager(), showingQRCode: $showingQRCode)
}
