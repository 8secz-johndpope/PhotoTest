//
//  CameraViewController.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 07.10.2020.
//

import UIKit
import AVFoundation
import Photos

class Camera2ViewController: UIViewController {
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var recordButton: UIButton!
    
    private lazy var camera: CameraManager = .init { (camera) in
        camera.photoPreset = .photo
        camera.videoPreset = .high
    }
    
    private lazy var mediaHelper: MediaHelper = .init()
    
    private var tapGR: DelayTapGestureRecognizer!
    private var recordGR: RecordGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        camera.previewView = previewView
        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        previewView.clipsToBounds = true
        
        camera.photoCaptureDelegate = self
        camera.recordingCaptureDelegate = self
        
        camera.flashMode = .off
        
        recordGR = RecordGestureRecognizer(target: self, action: #selector(recordButtonTapped(_:)), timeout: 100)
        tapGR = DelayTapGestureRecognizer(target: self, action: #selector(takePhotoTapped), tapDelay: 0.22)
        recordGR.require(toFail: tapGR)
        
        recordButton.addGestureRecognizer(recordGR)
        recordButton.addGestureRecognizer(tapGR)
        
        camera.checkAuthorizationStatus { [weak self] (status) in
            switch status {
            case .notDetermined:
                self?.camera.requestAccess(nil)
            default:
                break
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switch camera.setupResult {
        case let .configurationFailed(error):
            handleCameraError(error)
        case .notAuthorized:
            showTurnOnCameraAlert()
        default:
            break
        }
    }
    
    func handleCameraError(_ error: CameraManager.CameraError) {
        switch error {
        case .unavailable:
            showInfoAlert("Камера недоступна")
        case .videoInput:
            showInfoAlert("Не удалось создать или добавить Video Input")
        }
    }

    @objc func recordButtonTapped(_ recognizer: RecordGestureRecognizer) {
        if recognizer.state == .began {
            startRecording()
        } else if recognizer.state == .changed {
            zoomForRecognizer(recognizer)
        } else if recognizer.state == .ended {
            stopRecording()
        }
    }
    
    func zoomForRecognizer(_ recognizer: RecordGestureRecognizer) {
        guard
            let translation = recognizer.translation(in: previewView),
            let recognizerView = recognizer.view else { return }
        
        let zeroY = recognizerView.convert(recognizerView.bounds.origin, to: previewView).y
        
        if translation.y > 100, translation.y < zeroY {
            let panningY = zeroY - translation.y
            let zoomFactor = (panningY * (camera.maxZoomFactor - 1) / zeroY) + 1
            camera.zoom(factor: zoomFactor)
        }
    }
    
    func startRecording() {
        camera.useVideoConfiguration { [weak self] in
            self?.camera.startRecording()
            self?.recordButton.backgroundColor = .red
        }
    }
    
    func stopRecording() {
        camera.stopRecording()
        recordButton.backgroundColor = .blue
    }
    
    @objc func takePhotoTapped() {
        camera.capturePhoto()
    }
    
//    @IBAction func takePhoto(_ sender: Any) {
//        camera.usePhotoConfiguration({
//
//        }, removeVideoOutput: false)
//    }
    
//    var tMode = false
//    @IBAction func touchTapped(_ sender: Any) {
//        camera.setTorchMode(tMode ? .off : .on)
//        tMode = !tMode
//    }
//
//    @IBAction func changeCamTapped(_ sender: Any) {
//        camera.changeCamera { (error) in
//
//        }
//    }
    
}

extension Camera2ViewController: PhotoCaptureDelegate {
    
    func photoCaptureDidFinishCapture(_ capture: PhotoCaptureProcessor.Capture?, photoSettings: AVCapturePhotoSettings, error: Error?) {
        if let capture = capture {
            mediaHelper.saveToPhoto(capture: capture, settings: photoSettings)
        }
    }
    
}

extension Camera2ViewController: RecordingCaptureDelegate {
    
    func recordingCaptureDidFinishRecordingToTmpFile(_ outputFileURL: URL) {
        mediaHelper.saveToPhoto(fileURl: outputFileURL, type: .video)
    }
    
}
