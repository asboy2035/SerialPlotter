//
//  PlaceholderItem.swift
//  SerialPlotter
//
//  Created by ash on 8/28/25.
//


import SwiftUI

struct PlaceholderItem: View {
    let systemImage: String
    let systemImageColor: Color
    let title: String
    let subtitle: String
    var isProminent: Bool = false
    
    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundStyle(systemImageColor)
                .modifier(GradientSymbolIfAvailable())
                .background(
                    Image(systemName: systemImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(systemImageColor.opacity(0.6))
                        .modifier(GradientSymbolIfAvailable())
                        .blur(radius: 6)
                )
            
            VStack(spacing: 4) {
                Text(title)
                    .font(isProminent ? .title2 : .headline)
                Text(subtitle)
                    .font(.caption)
            }
            .foregroundStyle(isProminent ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
