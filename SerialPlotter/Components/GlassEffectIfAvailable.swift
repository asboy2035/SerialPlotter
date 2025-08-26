//
//  GlassEffectIfAvailable.swift
//  SerialPlotter
//
//  Created by ash on 8/17/25.
//

import SwiftUI

struct GlassEffectIfAvailable: ViewModifier {
    var radius: CGFloat?

    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, *) {
#if !os(visionOS)
            if let radius = radius {
                content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius))
            } else {
                content.glassEffect()
            }
#else
            content
#endif
        } else {
            content // fallback for older OSes
        }
    }
}

#Preview {
    RoundedRectangle(cornerRadius: 18)
        .frame(width: 180, height: 120)
        .modifier(GlassEffectIfAvailable(radius: 18))
}
