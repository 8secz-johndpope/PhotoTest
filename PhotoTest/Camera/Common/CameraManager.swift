//
//  CameraManager.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 09.10.2020.
//

import AVFoundation
import Photos
import UIKit

protocol CameraManagerDelegate: class {
    func baseCameraManagerDidChangeRunningStatus(isRunning: Bool)
    func baseCameraManagerIsSucceededResumingSession(_ isSucceeded: Bool)
    
    func baseCameraManagerSystemPressureStateChange(_ systemPressureState: AVCaptureDevice.SystemPressureState)
    
    func baseCameraManagerSessionInterruptionEnded()
    func baseCameraManagerSessionWasInterrupted(with reason: AVCaptureSession.InterruptionReason)
    func baseCameraManagerSessionRuntimeError(_ error: AVError)
}

class CameraManager: NSObject {
    
    // MARK: - Helpers Types
    enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
        
        var isSuccess: Bool {
            switch self {
            case .success: return true
            default: return false
            }
        }
    }
    
    enum Configuration: Int {
        case photo
        case video
    }

    // MARK: - Public properties
    var deviceOrientation: UIDeviceOrientation {
        UIDevice.current.orientation
    }
    
    var maxZoomFactor: CGFloat {
        videoDeviceInput.device.activeFormat.videoMaxZoomFactor
    }
    
    var isFlashAvailable: Bool {
        self.videoDeviceInput.device.isFlashAvailable
    }
    
    var maxExposure: Float {
        videoDeviceInput.device.maxExposureTargetBias
    }
    
    var minExposure: Float {
        videoDeviceInput.device.minExposureTargetBias
    }
    
    var videoDevice: AVCaptureDevice {
        videoDeviceInput.device
    }
    
    var setupResult: SessionSetupResult = .success
    
    weak var previewView: PreviewView! {
        didSet {
            previewView.videoPreviewLayer.session = session
        }
    }
    
    weak var cameraDelegate: CameraManagerDelegate?
    
    // MARK: Modes
    // Modes values override in `configureSession`,
    // the values depend on their support on the device
    var livePhotoModeEnable: Bool {
        set {
            _livePhotoModeEnable = photoOutput.isLivePhotoCaptureSupported && newValue
        }
        get {
            _livePhotoModeEnable && photoOutput.isLivePhotoCaptureSupported
        }
    }
    
    var depthDataDeliveryModeEnable: Bool {
        set {
            _depthDataDeliveryModeEnable = photoOutput.isDepthDataDeliverySupported && newValue
        }
        get {
            _depthDataDeliveryModeEnable && photoOutput.isDepthDataDeliverySupported
        }
    }
    
    var portraitEffectsMatteDeliveryModeEnable: Bool {
        set {
            _portraitEffectsMatteDeliveryModeEnable = photoOutput.isPortraitEffectsMatteDeliverySupported && newValue
        }
        get {
            _portraitEffectsMatteDeliveryModeEnable && photoOutput.isPortraitEffectsMatteDeliverySupported
        }
    }
    
    var flashMode: AVCaptureDevice.FlashMode = .auto
    var videoCodec: AVVideoCodecType = .hevc
    var photoCodec: AVVideoCodecType = .hevc
    var livePhotoCodec: AVVideoCodecType = .hevc
    var livePhotoFileFormat: VideoFileType = .mp4
    var videoFileFormat: VideoFileType = .mp4
    
    /// - Tag: set this property in `init(configurator: (CameraManager) -> Void)`
    var photoPreset: AVCaptureSession.Preset = .photo
    var videoPreset: AVCaptureSession.Preset = .high
    
    var currentConfiguration: Configuration = .photo
    
    // MARK: - Proxy Delegates
    weak var photoCaptureProcessor: AVCapturePhotoCaptureDelegate?
    weak var recordingCaptureProcessor: AVCaptureFileOutputRecordingDelegate?
    
    // MARK: Outputs
    let photoOutput: AVCapturePhotoOutput = .init()
    var movieFileOutput: AVCaptureMovieFileOutput?
    
    // For subclass usage
    let session: AVCaptureSession = .init()
    let sessionQueue: DispatchQueue = .init(label: "spider.ru.camera")
    
    // MARK: Inputs
    @objc dynamic private var videoDeviceInput: AVCaptureDeviceInput!
    
    // MARK: - Private properties
    private var isSessionRunning = false
    private var keyValueObservations: [NSKeyValueObservation] = []
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
        mediaType: .video,
        position: .unspecified)
    
    private var _livePhotoModeEnable: Bool = true
    private var _depthDataDeliveryModeEnable: Bool = true
    private var _portraitEffectsMatteDeliveryModeEnable: Bool = true
    
    // MARK: - init
    init(configurator: (CameraManager) -> Void) {
        super.init()
        configurator(self)
    }
    
    // MARK: - deinit
    deinit {
        print("DEINIT \(self)")
    }
    
    // MARK: - Public methods
    func requestAuthorizationStatus(completion: ((AVAuthorizationStatus) -> Void)?) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            setupResult = .success
            
            sessionQueue.async {
                self.configureSession()
            }
            
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] granted in
                self?.setupResult = granted ? .success : .notAuthorized
                self?.sessionQueue.resume()
                
                if granted {
                    self?.configureSession()
                }
            })
            
        default:
            setupResult = .notAuthorized
        }
        
        completion?(status)
    }
    
    func startSession() {
        guard setupResult.isSuccess else { return }
        
        sessionQueue.async {
            self.addObservers()
            
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            NotificationCenter.default.removeObserver(self)
            self.keyValueObservations.forEach { $0.invalidate() }
            self.keyValueObservations.removeAll()
            
            self.session.stopRunning()
            self.isSessionRunning = self.session.isRunning
        }
    }
    
    func resumeInterruptedSession() {
        sessionQueue.async {
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            
            DispatchQueue.main.async {
                self.cameraDelegate?.baseCameraManagerIsSucceededResumingSession(self.session.isRunning)
            }
        }
    }
    
    // Remove the AVCaptureMovieFileOutput from the session because it doesn't support capture of Live Photos.
    func usePhotoConfiguration(removeVideoOutput: Bool, completion: (() -> Void)?) {
        sessionQueue.async {
            self.session.beginConfiguration()
            
            if removeVideoOutput, let movieFileOutput = self.movieFileOutput {
                self.session.removeOutput(movieFileOutput)
                self.movieFileOutput = nil
            }
            
            self.session.sessionPreset = self.photoPreset
            
            if self.photoOutput.isLivePhotoCaptureSupported {
                self.photoOutput.isLivePhotoCaptureEnabled = self.livePhotoModeEnable
            }
            
            if self.photoOutput.isDepthDataDeliverySupported {
                self.photoOutput.isDepthDataDeliveryEnabled = self.depthDataDeliveryModeEnable
            }
            
            if self.photoOutput.isPortraitEffectsMatteDeliverySupported {
                self.photoOutput.isPortraitEffectsMatteDeliveryEnabled = self.portraitEffectsMatteDeliveryModeEnable
            }
            
            if #available(iOS 13.0, *) {
                if !self.photoOutput.availableSemanticSegmentationMatteTypes.isEmpty {
                    self.photoOutput.enabledSemanticSegmentationMatteTypes = self.photoOutput.availableSemanticSegmentationMatteTypes
                }
            }
            
            self.session.commitConfiguration()
            
            self.currentConfiguration = .photo
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func useVideoConfiguration(completion: (() -> Void)?) {
        sessionQueue.async {
            let movieFileOutput = AVCaptureMovieFileOutput()
            
            if self.session.canAddOutput(movieFileOutput) {
                self.session.beginConfiguration()
                self.session.addOutput(movieFileOutput)
                self.session.sessionPreset = self.videoPreset
                if let connection = movieFileOutput.connection(with: .video) {
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }
                self.session.commitConfiguration()
                
                self.movieFileOutput = movieFileOutput
                self.currentConfiguration = .video
            }
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func startRecording() {
        guard let recordingCaptureProcessor = recordingCaptureProcessor else {
            assertionFailure("\(#function)\nBaseCameraManager warning: set AVCaptureFileOutputRecordingDelegate")
            return
        }
        
        guard let movieFileOutput = self.movieFileOutput, !movieFileOutput.isRecording else {
            return
        }
        
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            let movieFileOutputConnection = movieFileOutput.connection(with: .video)
            movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
            
            let availableVideoCodecTypes = movieFileOutput.availableVideoCodecTypes
            
            if availableVideoCodecTypes.contains(self.videoCodec) {
                movieFileOutput.setOutputSettings([AVVideoCodecKey: self.videoCodec], for: movieFileOutputConnection!)
            }
            
            movieFileOutput.startRecording(to: .generateFileURL(type: self.videoFileFormat), recordingDelegate: recordingCaptureProcessor)
        }
    }
    
    func stopRecording() {
        guard let movieFileOutput = self.movieFileOutput, movieFileOutput.isRecording else {
            return
        }
        
        sessionQueue.async {
            movieFileOutput.stopRecording()
        }
    }
    
    func capturePhoto() {
        guard let photoCaptureProcessor = photoCaptureProcessor else {
            assertionFailure("\(#function)\nBaseCameraManager warning: set AVCapturePhotoCaptureDelegate")
            return
        }
        
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            var photoSettings = AVCapturePhotoSettings()
            
            if  self.photoOutput.availablePhotoCodecTypes.contains(self.photoCodec) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: self.photoCodec])
            }
            
            photoSettings.livePhotoVideoCodecType = self.livePhotoCodec
            
            if self.isFlashAvailable {
                photoSettings.flashMode = self.flashMode
            }
            
            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }
            // Live Photo capture is not supported in movie mode.
            if self.livePhotoModeEnable && self.photoOutput.isLivePhotoCaptureSupported {
                photoSettings.livePhotoMovieFileURL = .generateFileURL(type: self.livePhotoFileFormat)
            }
            
            photoSettings.isDepthDataDeliveryEnabled = self.depthDataDeliveryModeEnable
            photoSettings.isPortraitEffectsMatteDeliveryEnabled = self.portraitEffectsMatteDeliveryModeEnable
            
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }
    
    func zoom(factor: CGFloat) {
        sessionQueue.async {
            do {
                try self.videoDeviceInput.device.lockForConfiguration()
                self.videoDeviceInput.device.videoZoomFactor = factor
                self.videoDeviceInput.device.unlockForConfiguration()
            } catch let error {
                assertionFailure("BaseCameraManager did receive error: \(error)")
            }
        }
    }
    
    func setTorchMode(_ mode: AVCaptureDevice.TorchMode) {
        sessionQueue.async {
            do {
                try self.videoDeviceInput.device.lockForConfiguration()
                if self.videoDeviceInput.device.isTorchAvailable {
                    self.videoDeviceInput.device.torchMode = mode
                }
                self.videoDeviceInput.device.unlockForConfiguration()
            } catch let error {
                assertionFailure("BaseCameraManager did receive error: \(error)")
            }
        }
    }
    
    func changeCamera(completion: ((Error?) -> Void)?) {
        sessionQueue.async {
            var error: Error?
            
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInTrueDepthCamera
                
            @unknown default:
                assertionFailure("\(#function)\nBaseCameraManager warning: Unknown capture position. Defaulting to back, dual-camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
            }
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            // First, seek a device with both the preferred position and device type. Otherwise, seek a device with only the preferred position.
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, because AVCaptureSession doesn't support
                    // simultaneous use of the rear and front cameras.
                    self.session.removeInput(self.videoDeviceInput)
                    //
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
                        
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                    }
                    if let connection = self.movieFileOutput?.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    
                    /*
                     Set Live Photo capture and depth data delivery if it's supported. When changing cameras, the
                     `livePhotoCaptureEnabled` and `depthDataDeliveryEnabled` properties of the AVCapturePhotoOutput
                     get set to false when a video device is disconnected from the session. After the new video device is
                     added to the session, re-enable them on the AVCapturePhotoOutput, if supported.
                     */
                    self.photoOutput.isLivePhotoCaptureEnabled = self.livePhotoModeEnable
                    self.photoOutput.isDepthDataDeliveryEnabled = self.depthDataDeliveryModeEnable
                    self.photoOutput.isPortraitEffectsMatteDeliveryEnabled = self.portraitEffectsMatteDeliveryModeEnable
                    
                    self.session.commitConfiguration()
                } catch let captureDeviceError {
                    error = captureDeviceError
                }
            }
            
            DispatchQueue.main.async {
                completion?(error)
            }
        }
    }
    
}

// MARK: - Private -
private extension CameraManager {
    
    func configureSession() {
        guard setupResult.isSuccess else { return }
        
        session.beginConfiguration()
        
        /*
         Do not create an AVCaptureMovieFileOutput when setting up the session because
         Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
         */
        session.sessionPreset = self.photoPreset
        
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            /// - TODO: take from outside
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                print("BaseCameraManager warning: Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                     You can manipulate UIView only on the main thread.
                     Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if self.deviceOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: self.deviceOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("BaseCameraManager warning: Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            
        } catch {
            print("BaseCameraManager warning: Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("BaseCameraManager warning: Could not add audio device input to the session")
            }
            
        } catch {
            print("BaseCameraManager warning: Could not create audio device input: \(error)")
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            livePhotoModeEnable = photoOutput.isLivePhotoCaptureSupported && _livePhotoModeEnable
            depthDataDeliveryModeEnable = photoOutput.isDepthDataDeliverySupported && _depthDataDeliveryModeEnable
            portraitEffectsMatteDeliveryModeEnable = photoOutput.isPortraitEffectsMatteDeliverySupported && _portraitEffectsMatteDeliveryModeEnable
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = livePhotoModeEnable
            photoOutput.isDepthDataDeliveryEnabled = depthDataDeliveryModeEnable
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = portraitEffectsMatteDeliveryModeEnable
            
            if #available(iOS 13.0, *) {
                photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
                photoOutput.maxPhotoQualityPrioritization = .quality
            }
            
        } else {
            print("BaseCameraManager warning: Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    func addObservers() {
        let isRunningKVO = session.observe(\.isRunning, options: .new) { [weak self] _, change in
            guard let isSessionRunning = change.newValue else { return }

            DispatchQueue.main.async {
                self?.cameraDelegate?.baseCameraManagerDidChangeRunningStatus(isRunning: isSessionRunning)
            }
        }
        
        let systemPressureStateObservation = observe(\.videoDeviceInput.device.systemPressureState, options: .new) { [weak self] _, change in
            guard let systemPressureState = change.newValue else { return }
            self?.setRecommendedFrameRateRangeForPressureState(systemPressureState: systemPressureState)
        }
        
        keyValueObservations.append(isRunningKVO)
        keyValueObservations.append(systemPressureStateObservation)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subjectAreaDidChange),
            name: .AVCaptureDeviceSubjectAreaDidChange,
            object: videoDeviceInput.device
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionRuntimeError),
            name: .AVCaptureSessionRuntimeError,
            object: session
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted),
            name: .AVCaptureSessionWasInterrupted,
            object: session
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded),
            name: .AVCaptureSessionInterruptionEnded,
            object: session
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didChangeOrientation),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc func didChangeOrientation() {
        guard let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection else { return }
        let deviceOrientation = UIDevice.current.orientation
        
        guard
            let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
            deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
            return
        }
        
        videoPreviewLayerConnection.videoOrientation = newVideoOrientation
    }
    
    // MARK: - Session and Device errors
    
    func setRecommendedFrameRateRangeForPressureState(systemPressureState: AVCaptureDevice.SystemPressureState) {
        cameraDelegate?.baseCameraManagerSystemPressureStateChange(systemPressureState)
        
        let pressureLevel = systemPressureState.level
        if pressureLevel == .serious || pressureLevel == .critical {
            if self.movieFileOutput == nil || self.movieFileOutput?.isRecording == false {
                do {
                    try self.videoDeviceInput.device.lockForConfiguration()
                    print("BaseCameraManager warning: Reached elevated system pressure level: \(pressureLevel). Throttling frame rate.")
                    self.videoDeviceInput.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20)
                    self.videoDeviceInput.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
                    self.videoDeviceInput.device.unlockForConfiguration()
                } catch {
                    print("BaseCameraManager warning: Could not lock device for configuration: \(error)")
                }
            }
        }
    }
    
    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        print("\(#function)\nBaseCameraManager did receive error: \(error)")
        cameraDelegate?.baseCameraManagerSessionRuntimeError(error)
        
        // If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }
    
    // MARK: - Focus
    @objc func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    func focus(
        with focusMode: AVCaptureDevice.FocusMode,
        exposureMode: AVCaptureDevice.ExposureMode,
        at devicePoint: CGPoint,
        monitorSubjectAreaChange: Bool
    ) {
        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("BaseCameraManager warning: Could not lock device for configuration: \(error)")
            }
        }
    }
    
    // MARK: - Session Interruption
    
    // To resume session, see `resumeInterruptedSession(_:)`.
    @objc func sessionWasInterrupted(notification: NSNotification) {
        guard let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
              let reasonIntegerValue = userInfoValue.integerValue,
              let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) else { return }
        
        print("BaseCameraManager warning: Capture session was interrupted with reason \(reason)")
        cameraDelegate?.baseCameraManagerSessionWasInterrupted(with: reason)
    }
    
    @objc func sessionInterruptionEnded(notification: NSNotification) {
        print("BaseCameraManager: Capture session interruption ended")
        cameraDelegate?.baseCameraManagerSessionInterruptionEnded()
    }
    
}
