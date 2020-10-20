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
    weak var photoCaptureDelegate: XCPhotoCaptureDelegate?
    
    weak var recordingCaptureDelegate: XCRecordingCaptureDelegate? {
        didSet {
            xcRecordingCaptureProcessor.delegate = recordingCaptureDelegate
        }
    }
    
    // MARK: - Private properties
    private let audioSession = AVAudioSession.sharedInstance()
    
    private var cropRect: CGRect {
//        previewView.convert(previewView.bounds, to: nil)
        previewView.videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: previewView.bounds)
    }
    
    // MARK: - Proxy Delegates Factory
    private var xcPhotoCaptureProcessor: XCPhotoCaptureProcessor {
        photoCaptureProcessor as! XCPhotoCaptureProcessor
    }
    
    private var xcRecordingCaptureProcessor: XCRecordingCaptureProcessor {
        recordingCaptureProcessor as! XCRecordingCaptureProcessor
    }
    
    override init(configurator: (BaseCameraManager) -> Void) {
        super.init(configurator: { camera in
            configurator(camera)
            
            camera.photoCaptureProcessor = XCPhotoCaptureProcessor()
            camera.recordingCaptureProcessor = XCRecordingCaptureProcessor()
            
            camera.portraitEffectsMatteDeliveryModeEnable = false
            camera.depthDataDeliveryModeEnable = false
            camera.livePhotoModeEnable = false
        })
        
        sessionQueue.async {
            self.configureAudioSession()
        }
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
        sessionQueue.async {
            self.stopRecordingToChangeCamera()
            super.changeCamera { (error) in
                self.startRecording()
                completion?(error)
            }
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
