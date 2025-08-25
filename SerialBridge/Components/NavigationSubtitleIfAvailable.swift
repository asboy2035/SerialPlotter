//
//  NavigationSubtitleIfAvailable.swift
//  SerialBridge
//
//  Created by ash on 8/25/25.
//

import SwiftUI

struct NavigationSubtitleIfAvailable: ViewModifier {
    var subtitle: String

    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, *) {
#if !os(visionOS)
            content.navigationSubtitle(subtitle)
#else
            content
#endif
        } else {
            content // fallback for older OSes
        }
    }
}
