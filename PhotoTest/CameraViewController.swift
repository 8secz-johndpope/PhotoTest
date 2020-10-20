//
//  CameraViewController.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 19.10.2020.
//

import UIKit
import AVFoundation
import BetterSegmentedControl

class CameraViewController: UIViewController {

    // MARK: - Private properties
    private weak var previewView: PreviewView!
    private weak var activityIndicator: UIActivityIndicatorView!
    private weak var recordButton: UIButton!
    private weak var photoVideoControl: BetterSegmentedControl!
    private weak var changeCameraButton: UIButton!
    private weak var flashButton: UIButton!
    private weak var videoProgressView: UIProgressView!
    private weak var timerLabel: UILabel!
    
    private var camera: XCCameraManager!
    private var timer: RecordingTimer!
    private lazy var mediaHelper: MediaHelper = .init()
    
    private var configuration: BaseCameraManager.Configuration {
        BaseCameraManager.Configuration(rawValue: photoVideoControl.index) ?? .photo
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        let view = CameraView()
        self.view = view
        
        previewView = view.previewView
        activityIndicator = view.activityIndicator
        recordButton = view.recordButton
        photoVideoControl = view.photoVideoControl
        changeCameraButton = view.changeCameraButton
        flashButton = view.flashButton
        videoProgressView = view.videoProgressView
        timerLabel = view.timerLabel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        configureCamera()
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
    
    // MARK: - Private methods
    private func configureViews() {
        photoVideoControl.addTarget(self, action: #selector(photoVideoControlTapped(_:)), for: .valueChanged)
        recordButton.addTarget(self, action: #selector(recordButtonTapped(_:)), for: .touchUpInside)
        changeCameraButton.addTarget(self, action: #selector(changeCameraTapped), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(flashTapped), for: .touchUpInside)
    }
    
    private func configureCamera() {
        camera = XCCameraManager { [unowned self] (camera) in
            let camera = camera as! XCCameraManager
            camera.photoPreset = .photo
            camera.videoPreset = .high
            camera.flashMode = .off
            
            camera.previewView = self.previewView
            camera.photoCaptureDelegate = self
            camera.recordingCaptureDelegate = self
        }

        timer = RecordingTimer(
            displayProvider: MinutesSecondsRecordingProvider(),
            displayHandler: { [weak self] (timer, minSec) in
                self?.timerLabel.text = minSec
                UIView.animate(withDuration: 1) {
                    self?.videoProgressView.setProgress(timer.progress, animated: true)
                }
            }, endHandler: { [weak self] in
                // TODO:
            })
        
        camera.checkAuthorizationStatus { [weak self] (status) in
            switch status {
            case .notDetermined:
                self?.camera.requestAccess(nil)
            default:
                break
            }
        }
    }
    
    private func handleCameraError(_ error: BaseCameraManager.CameraError) {
        switch error {
        case .unavailable:
            showInfoAlert("Камера недоступна")
        case .videoInput:
            showInfoAlert("Не удалось создать или добавить Video Input")
        }
    }
    
    private func prepareUI(recording: Bool) {
        if recording {
            timerLabel.isHidden = false
            photoVideoControl.isEnabled = false
            flashButton.isHidden = true
        } else {
            videoProgressView.progress = 0
            timerLabel.isHidden = true
            timerLabel.text = "00:00"
            photoVideoControl.isEnabled = true
            flashButton.isHidden = false
        }
    }
    
    // MARK: - Actions
    @objc private func photoVideoControlTapped(_ control: BetterSegmentedControl) {
        recordButton.isEnabled = false
        
        if configuration == .photo {
            camera.usePhotoConfiguration(removeVideoOutput: true) { [weak self] in
                self?.recordButton.isEnabled = true
            }
        } else if configuration == .video {
            camera.useVideoConfiguration { [weak self] in
                self?.recordButton.isEnabled = true
            }
        }
        
        videoProgressView.isHidden = (configuration == .photo)
    }
    
    @objc private func recordButtonTapped(_ sender: UIButton) {
        switch configuration {
        case .photo:
            camera.capturePhoto()
            
        case .video:
            if sender.isSelected {
                timer.endTimer()
                camera.stopRecording()
                prepareUI(recording: false)
            } else {
                timer.startTimer()
                camera.startRecording()
                prepareUI(recording: true)
            }
            sender.isSelected = !sender.isSelected
        }
    }
    
    @objc private func changeCameraTapped() {
        camera.changeCamera(completion: nil)
    }
    
    @objc private func flashTapped() {
        
    }
    
}

extension CameraViewController: XCPhotoCaptureDelegate {
    
    func photoCaptureWillCapture() {
        previewView.videoPreviewLayer.opacity = 0
        UIView.animate(withDuration: 0.25) {
            self.previewView.videoPreviewLayer.opacity = 1
        }
    }
    
    func photoCaptureDidFinishCapture(image: UIImage?, photoSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let image = image {
            mediaHelper.saveToPhoto(photoData: image.pngData()!)
        }
    }
    
}

extension CameraViewController: XCRecordingCaptureDelegate {
    
    func recordingCaptureProcessingFiles(isProcessing: Bool) {
        isProcessing ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
    func recordingCaptureDidFinishRecordingToTmpFile(_ outputFileURL: URL) {
        mediaHelper.saveToPhoto(fileURl: outputFileURL, type: .video)
    }
    
    func recordingCaptureDidFinishWithError(_ error: Error) {
        showInfoAlert(error.localizedDescription)
    }
    
}
