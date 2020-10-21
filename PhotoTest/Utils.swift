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
    
    func saveToPhoto(photoData: Data, completion: ((Bool, Error?) -> Void)? = nil) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    
                    creationRequest.addResource(with: .photo, data: photoData, options: nil)
                    
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

extension UIImage {
    
    static var orientationFromDevice: UIImage.Orientation {
        switch UIDevice.current.orientation {
        case .landscapeRight:
            return .down
        case .landscapeLeft:
            return .up
        case .portraitUpsideDown:
            return .left
        default:
            return .right
        }
    }
    
    static func transformForOrientation(orientation: UIImage.Orientation) -> CGAffineTransform {
        switch orientation {
        case .right:
            return CGAffineTransform.identity.rotated(by: -.pi / 2)
        case .down:
            return CGAffineTransform.identity.rotated(by: .pi)
        case .left:
            return CGAffineTransform.identity.rotated(by: .pi / 2)
        default:
            return .identity
        }
    }

}

extension CGImagePropertyOrientation {
    
    var isPortrait: Bool {
        switch self {
        case .right, .left, .leftMirrored, .rightMirrored: return true
        default: return false
        }
    }
    
}
