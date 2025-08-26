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
        NavigationView {
            VStack(spacing: 20) {
                if showingQRCode {
                    QRCodeView(networkManager: networkManager)
                } else {
                    InstructionsView(showingQRCode: $showingQRCode, networkManager: networkManager)
                }
            }
            .navigationTitle("Mobile Connection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if networkManager.isConnected {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Disconnect") {
                            networkManager.stopListening()
                            dismiss()
                        }
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}
