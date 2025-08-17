//
//  DeviceReading.swift
//  SerialPlotter
//
//  Created by ash on 8/17/25.
//

import Foundation

struct DeviceReading: Identifiable {
    let id = UUID()
    let timestamp: Date
    let chargingRate: Double
    let newCharge: Double
    let battery: Double
    let charging: Bool
    let dimmer: Double
}
