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
        VStack {
            PlaceholderItem(
                systemImage: "iphone",
                systemImageColor: Color.purple,
                title: "Connect SerialBridge",
                subtitle: "Learn how to connect your iPhone.",
                isProminent: true
            )
            
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                InstructionStep(number: 1, text: "Open SerialBridge on your iPhone/iPad")
                InstructionStep(number: 2, text: "Tap \"QR Code\" on the mobile app")
                InstructionStep(number: 3, text: "Click \"Next\" below to show QR code")
                InstructionStep(number: 4, text: "Scan the QR code with your mobile device")
            }
        }
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
                .background(Circle().fill(.purple))
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}
