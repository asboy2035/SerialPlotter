//
//  StatusCard.swift
//  SerialPlotter
//
//  Created by ash on 8/17/25.
//

import SwiftUI

struct StatusCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.1))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
        .cornerRadius(18)
    }
}
