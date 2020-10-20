//
//  PhotoCaptureDelegate.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 13.10.2020.
//

import AVFoundation

protocol PhotoCaptureDelegate: class {
    func photoCaptureWillCapture()
    func photoCaptureDidStartLivePhotoProcessing()
    func photoCaptureDidFinishLivePhotoProcessing(with error: Error?)
    func photoCaptureDidFinishRecordingLivePhoto()
    func photoCaptureProcessingPhoto(isProcessing: Bool)
    func photoCaptureDidFinishCapture(_ capture: PhotoCaptureProcessor.Capture?, photoSettings: AVCapturePhotoSettings, error: Error?)
}

extension PhotoCaptureDelegate {
    func photoCaptureWillCapture() { }
    func photoCaptureDidStartLivePhotoProcessing() { }
    func photoCaptureDidFinishLivePhotoProcessing(with error: Error?) { }
    func photoCaptureDidFinishRecordingLivePhoto() { }
    func photoCaptureProcessingPhoto(isProcessing: Bool) { }
}
