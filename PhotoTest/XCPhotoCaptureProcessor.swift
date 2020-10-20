//
//  XCPhotoCaptureProcessor.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 13.10.2020.
//

import UIKit
import AVFoundation

class XCPhotoCaptureProcessor: NSObject {
    
    weak var delegate: XCPhotoCaptureDelegate?
    
    // MARK: - Configurations
    var cropRect: CGRect?
    
    // MARK: - Private properties
    private lazy var context = CIContext()
    
    // MARK: - Private methods
    private func cropImage(_ pixelBuffer: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cropImage = ciImage.cropped(to: cropRect ?? .zero)
        let image = UIImage(ciImage: cropImage)
        return image
    }
    
}

extension XCPhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        delegate?.photoCaptureWillCapture()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        var image: UIImage?
        
        if let pixelBuffer = photo.pixelBuffer {
            image = cropImage(pixelBuffer)
        }
        
        delegate?.photoCaptureDidFinishCapture(image: image, photoSettings: photo.resolvedSettings, error: error)
    }
    
}
