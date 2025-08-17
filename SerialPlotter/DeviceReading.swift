//
//  DeviceReading.swift
//  SerialPlotter
//
//  Created by ash on 8/17/25.
//

import Foundation

class DeviceReading: Identifiable {
    let id = UUID()
    let timestamp: Date
    var values: [String: Double]

    init(timestamp: Date, values: [String: Double]) {
        self.timestamp = timestamp
        self.values = values
    }
}