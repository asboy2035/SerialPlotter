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
                    .foregroundColor(.accentColor)
                
                Text("Connect SerialBridge")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                InstructionStep(number: 1, text: "Open SerialBridge on your iPhone/iPad")
                InstructionStep(number: 2, text: "Tap \"Connect\" on the mobile app")
                InstructionStep(number: 3, text: "Click \"Next\" below to show QR code")
                InstructionStep(number: 4, text: "Scan the QR code with your mobile device")
            }
            Spacer()
        }
        .padding()
        .frame(minWidth: 450, minHeight: 400)
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
                .background(Circle().fill(.accent))
                .modifier(GlassEffectIfAvailable())
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}
