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
    private weak var previewSnapshot: UIView!
    private weak var activityIndicator: UIActivityIndicatorView!
    private weak var recordButton: UIButton!
    private weak var photoVideoControl: BetterSegmentedControl!
    private weak var changeCameraButton: UIButton!
    private weak var flashButton: UIButton!
    private weak var videoProgressView: UIProgressView!
    private weak var timerLabel: UILabel!
    
    private weak var snapshot: UIView?
    private weak var controls: ControlsView?
    
    private var controlsWorkItem: DispatchWorkItem?
    
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
        previewSnapshot = view.previewSnapshot
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
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(previewTapped(_:)))
        previewView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(previewPanned(_:)))
        previewView.addGestureRecognizer(panGesture)
        
        tapGesture.require(toFail: panGesture)
        
        photoVideoControl.addTarget(self, action: #selector(photoVideoControlTapped(_:)), for: .valueChanged)
        recordButton.addTarget(self, action: #selector(recordButtonTapped(_:)), for: .touchUpInside)
        changeCameraButton.addTarget(self, action: #selector(changeCameraTapped), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(flashTapped), for: .touchUpInside)
    }
    
    private func configureCamera() {
        camera = XCCameraManager { [unowned self] (camera) in
            let camera = camera as! XCCameraManager
            camera.photoPreset = .photo
            camera.videoPreset = camera.preferredVideoPreset
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
        
//        camera.checkAuthorizationStatus { [weak self] (status) in
//            switch status {
//            case .notDetermined:
//                self?.camera.requestAccess(nil)
//            default:
//                break
//            }
//        }
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
        videoProgressView.isHidden = (configuration == .photo)
        recordButton.isEnabled = false
        showSnapshot()
        
        if configuration == .photo {
            camera.usePhotoConfiguration(removeVideoOutput: true) { [weak self] in
                self?.recordButton.isEnabled = true
                self?.hideSnapshot()
            }
        } else if configuration == .video {
            camera.useVideoConfiguration { [weak self] in
                self?.recordButton.isEnabled = true
                self?.hideSnapshot()
            }
        }
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
    
    @objc private func previewTapped(_ recognizer: UITapGestureRecognizer) {
        let touchPoint = recognizer.location(in: view)
        
        invalidateControlsWorkitem()
        hideControls()
        showControls(at: touchPoint)
        startControlsWorkitem()
    }
    
    @objc private func previewPanned(_ recognizer: UIPanGestureRecognizer) {
        guard let controls = controls else { return }
        switch recognizer.state {
        case .began:
            invalidateControlsWorkitem()
        
        case .changed:
            let yTranslation = recognizer.translation(in: view).y
            let translationFactor = yTranslation / view.frame.height
            controls.setExposureY(factor: translationFactor)
            print(camera.maxExposure, camera.minExposure)
            print(translationFactor)
        case .ended:
            startControlsWorkitem()
            
        default:
            break
        }
    }
    
    // MARK: - Helpers
    private func showSnapshot() {
        guard let snapshot = previewView.snapshotView(afterScreenUpdates: false) else { return }
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        
        snapshot.alpha = 0
        self.snapshot = snapshot
        
        self.snapshot?.addSubview(blurView)
        view.insertSubview(self.snapshot!, at: 1)
        
        blurView.pinToEdges()
        snapshot.pinToEdges()
        
        UIView.animate(withDuration: 0.2) {
            snapshot.alpha = 1
        }
    }
    
    private func hideSnapshot() {
        UIView.animate(withDuration: 0.2) {
            self.snapshot?.alpha = 0
        } completion: { (_) in
            self.snapshot?.removeFromSuperview()
        }
    }
    
    private func showControls(at point: CGPoint) {
        let cntrls: ControlsView = {
            let i = ControlsView(frame: .zero)
            i.frame.size = i.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            i.center = point
            i.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            return i
        }()
        controls = cntrls
        
        view.addSubview(controls!)
        
        UIView.animate(withDuration: 0.2) {
            self.controls?.transform = .identity
        }
    }
    
    private func hideControls() {
        controls?.removeFromSuperview()
        controls = nil
    }
    
    private func invalidateControlsWorkitem() {
        controlsWorkItem?.cancel()
        controlsWorkItem = nil
    }
    
    private func startControlsWorkitem() {
        controlsWorkItem = DispatchWorkItem { [weak self] in self?.hideControls() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: controlsWorkItem!)
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
            mediaHelper.saveToPhoto(photoData: image.jpegData(compressionQuality: 1)!)
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

private extension UIView {
    
    func pinToEdges() {
        snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
}
