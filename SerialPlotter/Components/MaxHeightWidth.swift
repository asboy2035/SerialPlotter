//
//  MaxHeightWidth.swift
//  SerialPlotter
//
//  Created by ash on 8/26/25.
//

import SwiftUI

struct MaxHeightWidth: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    }
}
