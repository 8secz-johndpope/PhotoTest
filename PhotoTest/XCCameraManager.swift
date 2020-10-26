//
//  XCCameraManager.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 20.10.2020.
//

import AVFoundation
import Photos
import UIKit

final class XCCameraManager: BaseCameraManager {
    
    // MARK: - Adapter Delegates
    weak var photoCaptureDelegate: XCPhotoCaptureDelegate? {
        didSet {
            xcPhotoCaptureProcessor.delegate = photoCaptureDelegate
        }
    }
    
    weak var recordingCaptureDelegate: XCRecordingCaptureDelegate? {
        didSet {
            xcRecordingCaptureProcessor.delegate = recordingCaptureDelegate
        }
    }
    
    var preferredVideoPreset: AVCaptureSession.Preset {
        let frontDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front
        )
        let tmpSession = AVCaptureSession()
        
        guard
            let frontCamera = frontDiscoverySession.devices.first,
            let videoDeviceInput = try? AVCaptureDeviceInput(device: frontCamera) else { return .hd1280x720 }
        
        tmpSession.addInput(videoDeviceInput)
        
        return tmpSession.preferredVideoPreset
    }
    
    // MARK: - Private properties
    private let audioSession = AVAudioSession.sharedInstance()
    
    private var cropRect: CGRect {
        previewView.convert(previewView.bounds, to: nil)
//        let metadataOutputRect = previewView.videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: previewView.frame)
//        let r2 = CGRect(x: metadataOutputRect.origin.x * previewView.bounds.size.width, y: metadataOutputRect.origin.y * previewView.bounds.size.height, width: metadataOutputRect.size.width * previewView.bounds.size.width, height: metadataOutputRect.size.height * previewView.bounds.size.height)
//        return r2
    }
    
    // MARK: - Proxy Delegates
    private var xcPhotoCaptureProcessor: XCPhotoCaptureProcessor {
        photoCaptureProcessor as! XCPhotoCaptureProcessor
    }
    
    private var xcRecordingCaptureProcessor: XCRecordingCaptureProcessor {
        recordingCaptureProcessor as! XCRecordingCaptureProcessor
    }
    
    // MARK: - init
    override init(configurator: (BaseCameraManager) -> Void) {
        super.init(configurator: { camera in
            camera.photoCaptureProcessor = XCPhotoCaptureProcessor()
            camera.recordingCaptureProcessor = XCRecordingCaptureProcessor()
            
            camera.portraitEffectsMatteDeliveryModeEnable = false
            camera.depthDataDeliveryModeEnable = false
            camera.livePhotoModeEnable = false
        
            configurator(camera)
        })
        
        sessionQueue.async {
            self.configureAudioSession()
        }
    }
    
    // MARK: - Overrides
    override func capturePhoto() {
        xcPhotoCaptureProcessor.cropRect = cropRect
        
        super.capturePhoto()
    }
    
    override func stopRecording() {
        xcRecordingCaptureProcessor.cropRect = cropRect
        xcRecordingCaptureProcessor.continueRecording = false
        
        super.stopRecording()
    }
    
    override func changeCamera(completion: ((Error?) -> Void)?) {
        if movieFileOutput?.isRecording ?? false {
            changeCameraWhileRecodring(completion)
        } else {
            super.changeCamera(completion: completion)
        }
    }
 
}

// MARK: - Private -
private extension XCCameraManager {
    
    func stopRecordingToChangeCamera() {
        guard let movieFileOutput = self.movieFileOutput, movieFileOutput.isRecording else {
            return
        }
        
        sessionQueue.async {
            self.xcRecordingCaptureProcessor.continueRecording = true
            movieFileOutput.stopRecording()
        }
    }
    
    func changeCameraWhileRecodring(_ completion: ((Error?) -> Void)?) {
        self.stopRecordingToChangeCamera()
        super.changeCamera { (error) in
            self.startRecording()
            completion?(error)
        }
    }
    
    func configureAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch let error as NSError {
            print("Could not set category. Error: \(error)")
        }
        
        session.automaticallyConfiguresApplicationAudioSession = false
    }
    
}

private extension AVCaptureSession {
    
    var preferredVideoPreset: Preset {
        if canSetSessionPreset(.hd4K3840x2160) {
            return .hd4K3840x2160
        }
        
        if canSetSessionPreset(.hd1920x1080) {
            return .hd1920x1080
        }
        
        if canSetSessionPreset(.hd1280x720) {
            return .hd1280x720
        }
        
        if canSetSessionPreset(.vga640x480) {
            return .vga640x480
        }
        
        return .cif352x288
    }
    
}
