//
//  Utils.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 09.10.2020.
//

import AVFoundation
import Photos
import UIKit

class MediaHelper {
    
    func removeFile(at url: URL) {
        let path = url.path
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("Could not remove file at url: \(url)")
            }
        }
    }

    func saveToPhoto(fileURl: URL, type: PHAssetResourceType, _ completion: ((Bool, Error?) -> Void)? = nil) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: type, fileURL: fileURl, options: nil)
                }, completionHandler: completion)
            }
        }
    }
    
    func saveToPhoto(capture: PhotoCaptureProcessor.Capture, settings: AVCapturePhotoSettings, completion: ((Bool, Error?) -> Void)? = nil) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    options.uniformTypeIdentifier = settings.processedFileType.map { $0.rawValue }
                    
                    if let photoData = capture.photoData {
                        creationRequest.addResource(with: .photo, data: photoData, options: options)
                    }
                    
                    if let livePhotoCompanionMovieURL = capture.livePhotoCompanionMovieURL {
                        let livePhotoCompanionMovieFileOptions = PHAssetResourceCreationOptions()
                        livePhotoCompanionMovieFileOptions.shouldMoveFile = true
                        creationRequest.addResource(with: .pairedVideo,
                                                    fileURL: livePhotoCompanionMovieURL,
                                                    options: livePhotoCompanionMovieFileOptions)
                    }
                    
                    // Save Portrait Effects Matte to Photos Library only if it was generated
                    if let portraitEffectsMatteData = capture.portraitEffectsMatteData {
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo,
                                                    data: portraitEffectsMatteData,
                                                    options: nil)
                    }
                    // Save Portrait Effects Matte to Photos Library only if it was generated
                    for semanticSegmentationMatteData in capture.semanticSegmentationMatteDataArray {
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo,
                                                    data: semanticSegmentationMatteData,
                                                    options: nil)
                    }
                    
                }, completionHandler: completion)
            }
        }
    }
    
}

extension AVCaptureVideoOrientation {
    
    public init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        case .portraitUpsideDown: self = .portraitUpsideDown
        default: return nil
        }
    }
    
}

extension URL {

    static var generateVideoURl: URL {
        let outputFileName = NSUUID().uuidString
        let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
        return URL(fileURLWithPath: outputFilePath)
    }
    
}