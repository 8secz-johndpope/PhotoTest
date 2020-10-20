//
//  RecordingCaptureDelegate.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 13.10.2020.
//

import Foundation

/**
 RecordingCaptureDelegate provides methods for interaction with video recording
 */
protocol RecordingCaptureDelegate: class {
    
    /// - Warning
    ///     You should call `saveToPhoto` before `cleanup`
    ///     Also you should check `error` after calling `saveToPhoto` cause `saveToPhoto` may finish with error
    /// - Parameter outputFileURL: The url for temporary video file
    /// - Parameter error: Pointer to error
    /// - Parameter cleanup: Closure to cleanup temporary video file at `outputFileURL`
    /// - Parameter saveToPhotos: Closure to save temporary video file to Photo app
    func recordingCaptureDidFinishRecordingToTmpFile(_ outputFileURL: URL)
    func recordingCaptureDidFinishWithError(_ error: Error)
    func recordingCaptureDidStartRecordingToFile(_ url: URL)
    func recordingCaptureProcessingFiles(isProcessing: Bool)
}

extension RecordingCaptureDelegate {
    func recordingCaptureDidStartRecordingToFile(_ url: URL) { }
    func recordingCaptureDidFinishWithError(_ error: Error) { }
    func recordingCaptureProcessingFiles(isProcessing: Bool) { }
}
