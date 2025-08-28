//
//  GradientSymbolIfAvailable.swift
//  SerialPlotter
//
//  Created by ash on 8/28/25.
//


import SwiftUI

struct GradientSymbolIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.symbolColorRenderingMode(.gradient)
        } else {
            content
        }
    }
}
