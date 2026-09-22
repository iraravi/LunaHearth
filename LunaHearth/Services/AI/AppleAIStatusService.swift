import Foundation
import FoundationModels
import UIKit
import Darwin

@MainActor struct AppleAIStatusService: AIStatusProviding {
    func status() -> AIStatusSnapshot {
        var availability: AIAvailability = .olderOS
        var images = false
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available: availability = .ready
            case .unavailable(let reason):
                switch reason {
                case .appleIntelligenceNotEnabled: availability = .disabled
                case .modelNotReady: availability = .preparing
                case .deviceNotEligible: availability = .unsupportedDevice
                @unknown default: availability = .unavailable
                }
            }
            if #available(iOS 27.0, *), availability == .ready {
                images = SystemLanguageModel.default.capabilities.contains(.vision)
            }
        }
        var info = utsname(); uname(&info)
        let bytes = Mirror(reflecting: info.machine).children.compactMap { $0.value as? Int8 }.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        var hardware = String(decoding: bytes, as: UTF8.self)
        var device = UIDevice.current.model
        #if targetEnvironment(simulator)
        hardware = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Simulator"
        device += " Simulator"
        #endif
        return AIStatusSnapshot(device: device, hardware: hardware,
            system: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            availability: availability, supportsImageInput: images, checkedAt: .now)
    }
}
