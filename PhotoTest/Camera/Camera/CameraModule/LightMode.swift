//
//  LightMode.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 27.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import AVFoundation
import UIKit

enum LightMode: Int {
    case auto
    case on
    case off
    
    var image: UIImage {
        switch self {
        case .auto: return Asset.flashAuto.image
        case .off:  return Asset.flashOff.image
        case .on:   return Asset.flashOn.image
        }
    }
    
    var torch: AVCaptureDevice.TorchMode {
        switch self {
        case .auto: return .auto
        case .off:  return .off
        case .on:   return .on
        }
    }
    
    var flash: AVCaptureDevice.FlashMode {
        switch self {
        case .auto: return .auto
        case .off:  return .off
        case .on:   return .on
        }
    }
    
    func nextMode() -> LightMode {
        let nextRawValue = rawValue + 1
        let normallyRawValue = nextRawValue % 3
        return LightMode(rawValue: normallyRawValue)!
    }
}
