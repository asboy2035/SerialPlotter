//
//  SerialBridgeApp.swift
//  SerialBridge
//
//  Created by ash on 8/25/25.
//

import SwiftUI

@main
struct SerialBridgeApp: App {
    @StateObject private var mobileNetworkManager = MobileNetworkManager()

    var body: some Scene {
        WindowGroup {
            if #available(iOS 26.0, visionOS 26.0, *) {
                GlassEffectContainer {
                    ContentView(mobileNetworkManager: mobileNetworkManager)
                        .onOpenURL { url in
                            mobileNetworkManager.handleQRCode(url.absoluteString)
                        }
                }
            } else {
                ContentView(mobileNetworkManager: mobileNetworkManager)
                    .onOpenURL { url in
                        mobileNetworkManager.handleQRCode(url.absoluteString)
                    }
            }
        }
    }
}
