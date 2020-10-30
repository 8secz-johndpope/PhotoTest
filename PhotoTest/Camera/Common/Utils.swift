//
//  Utils.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 09.10.2020.
//

import AVFoundation
import Photos
import UIKit

enum VideoFileType: String {
    case mp4 = "mp4"
    case mov = "mov"
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

    static func generateFileURL(type: VideoFileType) -> URL {
        let outputFileName = NSUUID().uuidString
        let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension(type.rawValue)!)
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

extension CGAffineTransform {
    
    func cgImageOrientation() -> CGImagePropertyOrientation {
        var assetOrientation = CGImagePropertyOrientation.up
        
          if a == 0 && b == 1.0 && c == -1.0 && d == 0 {
            assetOrientation = .right
          } else if a == 0 && b == -1.0 && c == 1.0 && d == 0 {
            assetOrientation = .left
          } else if a == 1.0 && b == 0 && c == 0 && d == 1.0 {
            assetOrientation = .up
          } else if a == -1.0 && b == 0 && c == 0 && d == -1.0 {
            assetOrientation = .down
          }
          
        return assetOrientation
    }
    
}

extension AVAsset {
    
    convenience init?(url: URL?) {
        if let url = url {
            self.init(url: url)
        } else {
            return nil
        }
    }
    
}

extension AVPlayer {

    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
    
}

extension CACornerMask {
    
    static var bottomRight: CACornerMask = .layerMaxXMaxYCorner
    static var topRight: CACornerMask = .layerMaxXMinYCorner
    static var bottomLeft: CACornerMask = .layerMinXMaxYCorner
    static var topLeft: CACornerMask = .layerMinXMinYCorner
    
}

extension UIEdgeInsets {
    
    @discardableResult
    func top(_ inset: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: inset, left: left, bottom: bottom, right: right)
    }
    
    @discardableResult
    func left(_ inset: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: top, left: inset, bottom: bottom, right: right)
    }
    
    @discardableResult
    func right(_ inset: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: top, left: left, bottom: bottom, right: inset)
    }
    
    @discardableResult
    func bottom(_ inset: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: top, left: left, bottom: inset, right: right)
    }
    
}
