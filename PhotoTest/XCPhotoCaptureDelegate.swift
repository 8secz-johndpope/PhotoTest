//
//  PhotoCaptureDelegate.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 13.10.2020.
//

import AVFoundation
import UIKit

protocol XCPhotoCaptureDelegate: class {
    func photoCaptureWillCapture()
    func photoCaptureDidFinishCapture(image: UIImage?, photoSettings: AVCaptureResolvedPhotoSettings, error: Error?)
}

extension XCPhotoCaptureDelegate {
    func photoCaptureWillCapture() { }
}
