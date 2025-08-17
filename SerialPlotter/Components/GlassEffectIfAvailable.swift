//
//  GlassEffectIfAvailable.swift
//  SerialPlotter
//
//  Created by ash on 8/17/25.
//

import SwiftUI

struct GlassEffectIfAvailable: ViewModifier {
    var radius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, *) {
#if !os(visionOS)
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius))
#else
            content
#endif
        } else {
            content // fallback for older OSes
        }
    }
}
