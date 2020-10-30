//
//  CameraOptions.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 29.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import Foundation

struct CameraOptions: OptionSet {
    let rawValue: UInt8
    
    static let photo = CameraOptions(rawValue: 1 << 0)
    static let video = CameraOptions(rawValue: 1 << 1)
    
    var isPhotoOnly: Bool {
        rawValue == (1 << 0)
    }
    
    var isVideoOnly: Bool {
        rawValue == (1 << 1)
    }
}
