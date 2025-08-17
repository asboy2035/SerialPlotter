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
    var selected: Bool = false

    init(title: String, value: String, color: Color, selected: Bool = false) {
        self.title = title
        self.value = value
        self.color = color
        self.selected = selected
    }

    init(title: String, value: Double, color: Color, selected: Bool = false) {
        self.title = title
        self.color = color
        if value == 1.0 {
            self.value = "yes"
        } else if value == 0.0 {
            self.value = "no"
        } else {
            self.value = String(format: "%.2f", value)
        }
        self.selected = selected
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.largeTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Spacer()
        }
        .padding(12)
        .frame(minWidth: 125)
        .modifier(GlassEffectIfAvailable(radius: 18))
        .background {
            if selected {
                color.opacity(0.2)
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .cornerRadius(18)
    }
}

#Preview {
    HStack {
        StatusCard(title: "Battery", value: "5.01 V", color: .green, selected: true)
        StatusCard(title: "Charging Rate", value: "36", color: .blue)
    }
    .padding()
}
