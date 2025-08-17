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

    init(title: String, value: String, color: Color) {
        self.title = title
        self.value = value
        self.color = color
    }

    init(title: String, value: Double, color: Color) {
        self.title = title
        self.color = color
        if value == 1.0 {
            self.value = "yes"
        } else if value == 0.0 {
            self.value = "no"
        } else {
            self.value = String(format: "%.2f", value)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.largeTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(12)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 80)
        .background(color.opacity(0.2))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
        .cornerRadius(18)
    }
}

#Preview {
    HStack {
        StatusCard(title: "Battery", value: "5.01 V", color: .green)
        StatusCard(title: "Charging Rate", value: "36", color: .blue)
    }
    .padding()
}
