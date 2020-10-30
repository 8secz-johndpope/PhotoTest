//
//  PlayerView.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 27.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerView: UIView {
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
}
