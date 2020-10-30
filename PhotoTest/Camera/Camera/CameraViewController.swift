//
//  CameraViewController.swift
//  yourservice-ios
//
//  Created by Igor Sorokin on 26/10/2020.
//

import UIKit
import AVFoundation

protocol CameraControllerDelegate: class {
    func cameraControllerDidCapture(ysPhoto: YSPhoto)
    func cameraControllerDidRecording(ysVideo: YSVideo)
    func cameraControllerPermissionFailed()
}

extension CameraControllerDelegate {
    func cameraControllerDidCapture(ysPhoto: YSPhoto) { }
    func cameraControllerDidRecording(ysVideo: YSVideo) { }
}

class CameraViewController: UIViewController {
    
    weak var delegate: CameraControllerDelegate?
    
    private weak var previewView: PreviewView!
    private weak var videoButton: UIButton!
    private weak var photoButton: UIButton!
    private weak var secordsLabel: UILabel!
    private weak var progressView: UIProgressView!
    private weak var captureButton: CaptureButton!
    private weak var changeCamButton: UIBarButtonItem!
    private weak var flashButton: UIBarButtonItem!
    private weak var snapshot: UIView?
    
    private var viewModel: CameraViewModel!
    
    private var camera: CameraManager!
    private var timer: RecordingTimer!
    private var lightMode: LightMode = .auto
    private let options: CameraOptions
    
    init(options: CameraOptions, viewModel: CameraViewModel) {
        self.options = options
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("DEINIT \(self)")
    }

    override func loadView() {
        super.loadView()
        let view = CameraView(options: options)
        self.view = view
        previewView = view.previewView
        videoButton = view.videoButton
        photoButton = view.photoButton
        captureButton = view.captureButton
        secordsLabel = view.secordsLabel
        progressView = view.progressView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureCamera()
        configureViews()
        
        camera.requestAuthorizationStatus(completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkPermissions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        camera.stopSession()
        super.viewWillDisappear(animated)
    }

    private func configureNavigationBar() {
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: nil,
            action: nil
        )
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.tintColor = .white
        let changeCamButton = UIBarButtonItem(image: Asset.changeCam.image, style: .plain, target: self, action: #selector(changeCamTapped(_:)))
        let flashButton = UIBarButtonItem(image: lightMode.image, style: .plain, target: self, action: #selector(flashTapped(_:)))
        self.changeCamButton = changeCamButton
        self.flashButton = flashButton
        navigationItem.rightBarButtonItems = [changeCamButton, flashButton]
    }
    
    private func configureViews() {
        photoButton.addTarget(self, action: #selector(photoTapped(_:)), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(videoTapped(_:)), for: .touchUpInside)
        captureButton.addTarget(self, action: #selector(captureTapped(_:)), for: .touchUpInside)
    }

    private func configureCamera() {
        camera = CameraManager(configurator: { [unowned self] in
            $0.previewView = self.previewView
            
            $0.photoPreset = .photo
            $0.videoPreset = .hd1280x720
            $0.photoCodec = .jpeg
            $0.videoCodec = .h264
            $0.flashMode = lightMode.flash
            $0.livePhotoModeEnable = false
            $0.depthDataDeliveryModeEnable = false
            $0.portraitEffectsMatteDeliveryModeEnable = false
            
            $0.photoCaptureProcessor = self
            $0.recordingCaptureProcessor = self
        })
        
        if options.isVideoOnly {
            prepareUI(for: .video)
            camera.useVideoConfiguration(completion: { [weak self] in
                guard let self = self else { return }
                self.camera.setTorchMode(self.lightMode.torch)
            })
        }
        
        timer = RecordingTimer(
            displayProvider: MinutesSecondsRecordingProvider(),
            displayHandler: { [weak self] (timer, minSec) in
                self?.secordsLabel.text = minSec
                UIView.animate(withDuration: 1) {
                    self?.progressView.setProgress(timer.progress, animated: true)
                }
            }, endHandler: { [weak self] in
                self?.camera.stopRecording()
                self?.progressView.progress = 0
                self?.secordsLabel.text = "0:00"
            })
        
        timer.totalSeconds = Constants.CameraSettings.videoDuration
    }
    
    private func checkPermissions() {
        switch camera.setupResult {
        case .success:
            camera.startSession()
            
        case .configurationFailed:
            showAlert(
                title: "Ошибка",
                message: "Не удалось подключиться к камере, возможно она повреждена",
                actionTitle: "Закрыть",
                complete: { [weak self] in
                    self?.delegate?.cameraControllerPermissionFailed()
                })
            
        case .notAuthorized:
            showTurnOnCameraAlert()
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .denied, .restricted:
            showMicrophoneWarning()
            
        default:
            break
        }
    }

    // MARK: - Actions
    @objc private func changeCamTapped(_ sender: UIBarButtonItem) {
        controls(isEnable: false)
        camera.changeCamera(completion: { [weak self] error in
            self?.controls(isEnable: true)
            
            guard let error = error else { return }
            self?.showAlert(title: error.localizedDescription)
        })
    }
    
    @objc private func flashTapped(_ sender: UIBarButtonItem) {
        lightMode = lightMode.nextMode()
        flashButton.image = lightMode.image
        
        switch camera.currentConfiguration {
        case .photo:
            camera.setTorchMode(.off)
            camera.flashMode = lightMode.flash
            
        case .video:
            camera.setTorchMode(lightMode.torch)
            camera.flashMode = lightMode.flash
        }
    }
    
    @objc private func photoTapped(_ sender: UIButton) {
        photoButton.isSelected = true
        videoButton.isSelected = false
        
        controls(isEnable: false)
        showSnapshot()
        prepareUI(for: .photo)
        
        camera.setTorchMode(.off)
        camera.usePhotoConfiguration(removeVideoOutput: true, completion: { [weak self] in
            self?.controls(isEnable: true)
            self?.hideSnapshot()
        })
    }
    
    @objc private func videoTapped(_ sender: UIButton) {
        videoButton.isSelected = true
        photoButton.isSelected = false
        
        controls(isEnable: false)
        showSnapshot()
        prepareUI(for: .video)
        
        camera.useVideoConfiguration(completion: { [weak self] in
            guard let self = self else { return }
            self.camera.setTorchMode(self.lightMode.torch)
            self.controls(isEnable: true)
            self.hideSnapshot()
        })
    }
    
    @objc private func captureTapped(_ sender: CaptureButton) {
        switch camera.currentConfiguration {
        case .photo:
            camera.capturePhoto()
            
        case .video:
            let isRecoding = sender.isSelected
            if isRecoding {
                camera.stopRecording()
                timer.invalidate()
                progressView.progress = 0
                secordsLabel.text = "0:00"
            } else {
                camera.startRecording()
                timer.startTimer()
            }
            controls(isEnable: isRecoding)
            captureButton.isEnabled = true
            
            sender.isSelected = !sender.isSelected
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
    
    private func prepareUI(for config: CameraManager.Configuration) {
        switch config {
        case .photo:
            secordsLabel.isHidden = true
            progressView.isHidden = true
            photoButton.isSelected = true
            videoButton.isSelected = false
            
        case .video:
            secordsLabel.isHidden = false
            progressView.isHidden = false
            photoButton.isSelected = false
            videoButton.isSelected = true
        }
        
        captureButton.prepareForConfiguration(config)
    }
    
    private func controls(isEnable: Bool) {
        captureButton.isEnabled = isEnable
        videoButton.isEnabled = isEnable
        photoButton.isEnabled = isEnable
        changeCamButton.isEnabled = isEnable
        
        switch camera.currentConfiguration {
        case .photo:
            flashButton.isEnabled = isEnable && camera.videoDevice.isFlashAvailable
            
        case .video:
            flashButton.isEnabled = isEnable && camera.videoDevice.isTorchAvailable
        }
    }
    
}

// MARK: - AVCapturePhotoCaptureDelegate -
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        controls(isEnable: false)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        controls(isEnable: true)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        previewView.videoPreviewLayer.opacity = 0
        UIView.animate(withDuration: 0.25) {
            self.previewView.videoPreviewLayer.opacity = 1
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let ysPhoto = viewModel.processPhoto(photo) {
            delegate?.cameraControllerDidCapture(ysPhoto: ysPhoto)
        } else {
            showAlert(title: error?.localizedDescription)
        }
    }
    
}

// MARK: - AVCaptureFileOutputRecordingDelegate -
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let ysVideo = viewModel.processVideo(at: outputFileURL, from: output) {
            delegate?.cameraControllerDidRecording(ysVideo: ysVideo)
        } else {
            showAlert(title: error?.localizedDescription)
        }
    }
    
}

private extension UIView {
    
    func pinToEdges() {
        snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
}

private extension CameraViewController {
    
    func showTurnOnCameraAlert() {
        let settings = UIAlertAction(title: "Настройки", style: .default, handler: { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        })
        
        let cancel = UIAlertAction(title: "Закрыть", style: .cancel, handler: { [weak self] _ in
            self?.delegate?.cameraControllerPermissionFailed()
        })
        
        let alert = UIAlertController(title: "Включите камеру в настройках", message: nil, preferredStyle: .alert)
        alert.addAction(settings)
        alert.addAction(cancel)
        
        present(alert, animated: true)
    }
    
    func showMicrophoneWarning() {
        let settings = UIAlertAction(title: "Настройки", style: .default, handler: { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        })
        
        let cancel = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        
        let alert = UIAlertController(title: "Ваш микрофон выключен, чтобы записывать видео со звуком, включите его в настройках.", message: nil, preferredStyle: .alert)
        alert.addAction(settings)
        alert.addAction(cancel)
        
        present(alert, animated: true)
    }
    
}
