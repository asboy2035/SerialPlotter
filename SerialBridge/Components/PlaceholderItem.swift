//
//  PlaceholderItem.swift
//  SerialBridge
//
//  Created by ash on 8/28/25.
//

import SwiftUI

struct PlaceholderItem: View {
    let systemImage: String
    let systemImageColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundStyle(systemImageColor)
                .modifier(GradientSymbolIfAvailable())
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
