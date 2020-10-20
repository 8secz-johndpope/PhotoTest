/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's photo capture delegate object.
*/

import UIKit
import AVFoundation
import Photos

class PhotoCaptureProcessor: NSObject {
    
    struct Capture {
        var photoData: Data?
        var livePhotoCompanionMovieURL: URL?
        var portraitEffectsMatteData: Data?
        var semanticSegmentationMatteDataArray: [Data] = []
    }
    
    weak var delegate: PhotoCaptureDelegate?
    
    // MARK: - Handlers
    private let livePhotoCaptureHandler: (Bool) -> Void
    private let completionHandler: (PhotoCaptureProcessor) -> Void
    
    // MARK: - Configurations
    lazy var context = CIContext()
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    private var maxPhotoProcessingTime: CMTime?
    private let cropRect: CGRect
    
    // MARK: - Output data
    private var capture: Capture?
    
    // MARK: - init
    init(
        with requestedPhotoSettings: AVCapturePhotoSettings,
        cropRect: CGRect,
        livePhotoCaptureHandler: @escaping (Bool) -> Void,
        completionHandler: @escaping (PhotoCaptureProcessor) -> Void
    ) {
        self.requestedPhotoSettings = requestedPhotoSettings
        self.cropRect = cropRect
        self.livePhotoCaptureHandler = livePhotoCaptureHandler
        self.completionHandler = completionHandler
    }
    
}

// MARK: - AVCapturePhotoCaptureDelegate -
extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        capture = Capture()
        
        if resolvedSettings.livePhotoMovieDimensions.width > 0 && resolvedSettings.livePhotoMovieDimensions.height > 0 {
            delegate?.photoCaptureDidStartLivePhotoProcessing()
        }
        
        if #available(iOS 13, *) {
            maxPhotoProcessingTime = resolvedSettings.photoProcessingTimeRange.start + resolvedSettings.photoProcessingTimeRange.duration
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        delegate?.photoCaptureWillCapture()
        
        
        guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
            return
        }
        
        let oneSecond = CMTime(seconds: 1, preferredTimescale: 1)
        if maxPhotoProcessingTime > oneSecond {
            delegate?.photoCaptureProcessingPhoto(isProcessing: true)
        }
    }
    
    /// - Tag: DidFinishProcessingPhoto
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        delegate?.photoCaptureProcessingPhoto(isProcessing: false)
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
//            capture?.photoData
            let photoR = photo.file
            let sa = photoR?.takeRetainedValue()
            UIGraphicsImageRenderer(bounds: cropRect).image { (conte) in
                
            }
            
        }
        // A portrait effects matte gets generated only if AVFoundation detects a face.
        if var portraitEffectsMatte = photo.portraitEffectsMatte {
            if let orientation = photo.metadata[ String(kCGImagePropertyOrientation) ] as? UInt32 {
                portraitEffectsMatte = portraitEffectsMatte.applyingExifOrientation(CGImagePropertyOrientation(rawValue: orientation)!)
            }
            let portraitEffectsMattePixelBuffer = portraitEffectsMatte.mattingImage
            let portraitEffectsMatteImage = CIImage( cvImageBuffer: portraitEffectsMattePixelBuffer, options: [ .auxiliaryPortraitEffectsMatte: true ] )
            
            guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
                capture?.portraitEffectsMatteData = nil
                return
            }
            capture?.portraitEffectsMatteData = context.heifRepresentation(of: portraitEffectsMatteImage,
                                                                           format: .RGBA8,
                                                                           colorSpace: perceptualColorSpace,
                                                                           options: [.portraitEffectsMatteImage: portraitEffectsMatteImage])
        } else {
            capture?.portraitEffectsMatteData = nil
        }
        
        if #available(iOS 13.0, *) {
            for semanticSegmentationType in output.enabledSemanticSegmentationMatteTypes {
                handleMatteData(photo, ssmType: semanticSegmentationType)
            }
        }
    }
    
    @available(iOS 13.0, *)
    func handleMatteData(_ photo: AVCapturePhoto, ssmType: AVSemanticSegmentationMatte.MatteType) {
        
        guard var segmentationMatte = photo.semanticSegmentationMatte(for: ssmType) else { return }
        
        // Retrieve the photo orientation and apply it to the matte image.
        if let orientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
            let exifOrientation = CGImagePropertyOrientation(rawValue: orientation) {
            segmentationMatte = segmentationMatte.applyingExifOrientation(exifOrientation)
        }
        
        var imageOption: CIImageOption!
        
        switch ssmType {
        case .hair:
            imageOption = .auxiliarySemanticSegmentationHairMatte
        case .skin:
            imageOption = .auxiliarySemanticSegmentationSkinMatte
        case .teeth:
            imageOption = .auxiliarySemanticSegmentationTeethMatte
        default:
            print("This semantic segmentation type is not supported!")
            return
        }
        
        guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return }
        
        // Create a new CIImage from the matte's underlying CVPixelBuffer.
        let ciImage = CIImage( cvImageBuffer: segmentationMatte.mattingImage,
                               options: [imageOption: true,
                                         .colorSpace: perceptualColorSpace])
        
        guard let imageData = context.heifRepresentation(of: ciImage,
                                                         format: .RGBA8,
                                                         colorSpace: perceptualColorSpace,
                                                         options: [.depthImage: ciImage]) else { return }
        
        capture?.semanticSegmentationMatteDataArray.append(imageData)
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL,
        resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        delegate?.photoCaptureDidFinishRecordingLivePhoto()
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL,
        duration: CMTime,
        photoDisplayTime: CMTime,
        resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        if let error = error {
            delegate?.photoCaptureDidFinishLivePhotoProcessing(with: error)
            print("Error processing Live Photo companion movie: \(String(describing: error))")
            return
        }
        capture?.livePhotoCompanionMovieURL = outputFileURL
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        delegate?.photoCaptureDidFinishCapture(capture, photoSettings: requestedPhotoSettings, error: error)
    }
}
