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
    private func cropImage(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) -> UIImage? {
        let cropRect = self.cropRect ?? .zero
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(orientation)
        let naturalSize = ciImage.extent
        
        var scaleToFitRatio = naturalSize.height / cropRect.height
        if orientation.isPortrait {
            scaleToFitRatio = naturalSize.height / cropRect.width
        }
        
        let scaledHeight = cropRect.height * scaleToFitRatio
        let scaledWidth = cropRect.width * scaleToFitRatio
        let yCenterFactor = (naturalSize.height - scaledHeight) / 2
        let xCenterFactor = (naturalSize.width - scaledWidth) / 2
        let scaledRect = CGRect(x: xCenterFactor, y: yCenterFactor, width: scaledWidth, height: scaledHeight)
        
        let cropImage = ciImage.cropped(to: scaledRect)
        
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
        let orientationMetadata = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32
        let orientation = CGImagePropertyOrientation(rawValue: orientationMetadata ?? 6) // default right
        
        if let pixelBuffer = photo.previewPixelBuffer {
            image = cropImage(pixelBuffer, orientation: orientation ?? .right)
        }
        
        delegate?.photoCaptureDidFinishCapture(image: image, photoSettings: photo.resolvedSettings, error: error)
    }
    
}
