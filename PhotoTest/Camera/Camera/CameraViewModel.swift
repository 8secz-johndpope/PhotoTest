//
//  CameraViewModel.swift
//  yourservice-ios
//
//  Created by Igor Sorokin on 26/10/2020.
//

import UIKit
import AVFoundation

protocol CameraViewModel {
    func processPhoto(_ photo: AVCapturePhoto) -> YSPhoto?
    func processVideo(at fileURl: URL, from output: AVCaptureFileOutput) -> YSVideo?
} 

final class CameraViewModelImp: CameraViewModel {
    
    deinit {
        print("DEINIT \(self)")
    }
    
    func processPhoto(_ photo: AVCapturePhoto) -> YSPhoto? {
        guard let pixelBuffer = photo.previewPixelBuffer else { return nil }
        
        let orientationMetadata = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32
        let orientation = CGImagePropertyOrientation(rawValue: orientationMetadata ?? 6) // default right
        let image = CIImage(cvPixelBuffer: pixelBuffer).oriented(orientation ?? .right)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bounds = CGSize(width: width, height: height)
        
        return YSPhoto(image: image, bounds: bounds, date: Date())
    }
    
    func processVideo(at fileURl: URL, from output: AVCaptureFileOutput) -> YSVideo? {
        let duration = CMTimeGetSeconds(output.recordedDuration)
        let fileSize = output.recordedFileSize
        var bounds: CGSize?
        var codec: AVVideoCodecType?
        
        if
            let videoConnection = output.connection(with: .video),
            let settings = (output as? AVCaptureMovieFileOutput)?.outputSettings(for: videoConnection) {
            
            let width = settings[AVVideoWidthKey] as? CGFloat
            let height = settings[AVVideoHeightKey] as? CGFloat
            bounds = CGSize(width: width, height: height)
            codec = settings[AVVideoCodecKey] as? AVVideoCodecType
        }
        
        return YSVideo(url: fileURl, duration: duration, fileSize: fileSize, codec: codec, bounds: bounds, date: Date())
    }
    
}

private extension CGSize {
    
    init?(width: CGFloat?, height: CGFloat?) {
        if let width = width, let height = height {
            self.init(width: width, height: height)
        } else {
            return nil
        }
    }
    
}
