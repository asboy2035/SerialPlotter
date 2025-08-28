//
//  ConnectionOptionCard.swift
//  SerialBridge
//
//  Created by ash on 8/28/25.
//

import SwiftUI

struct ConnectionOptionCard: View {
    let systemImage: String
    let systemImageColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
                .foregroundStyle(systemImageColor)
                .modifier(GradientSymbolIfAvailable())
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title2)
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .modifier(GlassEffectIfAvailable(radius: 22))
    }
}
