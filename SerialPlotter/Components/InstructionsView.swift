//
//  InstructionsView.swift
//  SerialPlotter
//
//  Created by ash on 8/25/25.
//

import SwiftUI

struct InstructionsView: View {
    @Binding var showingQRCode: Bool
    @ObservedObject var networkManager: NetworkManager
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 15) {
                Image(systemName: "iphone")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Connect Mobile App")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionStep(number: 1, text: "Open SerialBridge on your iPhone/iPad")
                InstructionStep(number: 2, text: "Tap \"Connect\" on the mobile app")
                InstructionStep(number: 3, text: "Click \"Next\" below to show QR code")
                InstructionStep(number: 4, text: "Scan the QR code with your mobile device")
            }
            
            Button("Next") {
                networkManager.startServer()
                showingQRCode = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack {
            Text("\(number)")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
                .background(Circle().fill(.blue))
                .foregroundColor(.white)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}
