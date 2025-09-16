//
//  SerialPlotterApp.swift
//  SerialPlotter
//
//  Created by ash on 8/17/25.
//

import SwiftUI

@main
struct SerialPlotterApp: App {
    var body: some Scene {
        Window("Main", id: "serialMain") {
            ContentView()
                .onDisappear() {
                    NSApplication.shared.terminate(nil)
                }
        }
        .handlesExternalEvents(matching: Set(["start", "stop", "toggle"]))
    }
}
