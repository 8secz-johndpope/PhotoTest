//
//  PreviewView.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 07.10.2020.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    /// Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
}
