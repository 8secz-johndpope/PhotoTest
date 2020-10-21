//
//  RecordingCaptureProcessor.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 13.10.2020.
//

import UIKit
import AVFoundation
import Photos

final class XCRecordingCaptureProcessor: NSObject, AVCaptureFileOutputRecordingDelegate {
 
    weak var delegate: XCRecordingCaptureDelegate?
    var cropRect: CGRect?
    var continueRecording: Bool = false
    var preset: AVCaptureSession.Preset = .high
    
    private var tmpURls: [URL] = []
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            self.delegate?.recordingCaptureDidStartRecordingToFile(fileURL)
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        tmpURls.append(outputFileURL)
        if !continueRecording {
            DispatchQueue.main.async {
                self.delegate?.recordingCaptureProcessingFiles(isProcessing: true)
            }
            
            mergeCropFiles(at: tmpURls, cropRect: cropRect ?? .zero, preset: preset) { [weak self] (url, error) in
                self?.cleanupTmpURLs()
                
                DispatchQueue.main.async {
                    self?.delegate?.recordingCaptureProcessingFiles(isProcessing: false)
                }
                
                if let url = url {
                    DispatchQueue.main.async {
                        self?.delegate?.recordingCaptureDidFinishRecordingToTmpFile(url)
                    }
                } else if let error = error {
                    DispatchQueue.main.async {
                        self?.delegate?.recordingCaptureDidFinishWithError(error)
                    }
                }
            }
        }
    }
    
    // MARK: - Private -
    
    private func mergeCropFiles(at urls: [URL], cropRect: CGRect, preset: AVCaptureSession.Preset, completion: @escaping (URL?, Error?) -> Void) {
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let adoptRect = cropRect.adoptForAVC()
        
        let asset = AVAsset(url: urls.first)
        let assetVideoTrack = asset?.tracks(withMediaType: .video).first
        
        videoComposition.renderSize = assetVideoTrack?.scaledSize(for: adoptRect.size) ?? adoptRect.size
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 25)
        
        var insetTime: CMTime = .zero
        urls.forEach {
            let asset = AVAsset(url: $0)
            guard
                let assetVideoTrack = asset.tracks(withMediaType: .video).first,
                let assetAudioTrack = asset.tracks(withMediaType: .audio).first else {
                return
            }
            
            let instruction = assetVideoTrack.compositionInstructionForOrientation(
                for: CMTimeRangeMake(start: insetTime, duration: asset.duration),
                cropRect: adoptRect
            )
            videoComposition.instructions.append(instruction)
            
            try? videoTrack?.insertTimeRange(assetVideoTrack.timeRange, of: assetVideoTrack, at: insetTime)
            try? audioTrack?.insertTimeRange(assetAudioTrack.timeRange, of: assetAudioTrack, at: insetTime)
            
            insetTime = insetTime + asset.duration
        }
        
        let exporter = AVAssetExportSession(asset: composition, presetName: String(preset: preset))
        exporter?.videoComposition = videoComposition
        exporter?.outputURL = .generateVideoURl
        exporter?.outputFileType = .mov
        exporter?.exportAsynchronously(completionHandler: {
            if let url = exporter?.outputURL {
                completion(url, nil)
            } else if let error = exporter?.error {
                completion(nil, error)
            }
        })
    }
    
    private func cleanupTmpURLs() {
        tmpURls.forEach { [weak self] in
            self?.removeFile(at: $0)
        }
        tmpURls.removeAll()
    }
    
    private func removeFile(at url: URL) {
        let path = url.path
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("Could not remove file at url: \(url)")
            }
        }
    }
    
}

// MARK: - Helpers -
private extension AVAssetTrack {
    
    func scaledSize(for cropSize: CGSize) -> CGSize {
        let assetInfo = orientationFromTransform()
        
        var scaleToFitRatio = naturalSize.height / cropSize.height
        if assetInfo.isPortrait {
            scaleToFitRatio = naturalSize.height / cropSize.width
        }
        
        let scaleSize = CGSize(width: cropSize.width * scaleToFitRatio, height: cropSize.height * scaleToFitRatio)
        return scaleSize
    }
    
    func compositionInstructionForOrientation(for timeRange: CMTimeRange, cropRect: CGRect) -> AVMutableVideoCompositionInstruction {
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: self)
        
        var finalTransform = preferredTransform
        let scaleSize = scaledSize(for: cropRect.size)
        
        let yCenterFactor = (naturalSize.width - scaleSize.height) / 2
        let xCenterFactor = (naturalSize.height - scaleSize.width) / 2
        
        finalTransform.tx = finalTransform.tx - xCenterFactor
        finalTransform.ty = finalTransform.ty - yCenterFactor
        
        layerInstruction.setTransform(finalTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        
        return instruction
    }
    
    func orientationFromTransform() -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        let tfA = preferredTransform.a
        let tfB = preferredTransform.b
        let tfC = preferredTransform.c
        let tfD = preferredTransform.d
        
        if tfA == 0 && tfB == 1.0 && tfC == -1.0 && tfD == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if tfA == 0 && tfB == -1.0 && tfC == 1.0 && tfD == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if tfA == 1.0 && tfB == 0 && tfC == 0 && tfD == 1.0 {
            assetOrientation = .up
        } else if tfA == -1.0 && tfB == 0 && tfC == 0 && tfD == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
}

private extension CGRect {
    
    func adoptForAVC() -> CGRect {
        let size = CGSize(width: floor(width / 16) * 16, height: floor(height / 16) * 16)
        return CGRect(origin: origin, size: size)
    }
    
}

private extension String {
    
    init(preset: AVCaptureSession.Preset) {
        switch preset {
        case .hd1280x720:    self = AVAssetExportPreset1280x720
        case .hd1920x1080:   self = AVAssetExportPreset1920x1080
        case .hd4K3840x2160: self = AVAssetExportPreset3840x2160
        case .high:          self = AVAssetExportPresetHighestQuality
        case .low:              self = AVAssetExportPresetLowQuality
        case .medium:        self = AVAssetExportPresetMediumQuality
        case .vga640x480:    self = AVAssetExportPreset640x480
        case .iFrame960x540: self = AVAssetExportPreset960x540
        default:             self = AVAssetExportPresetPassthrough
        }
    }
    
}
