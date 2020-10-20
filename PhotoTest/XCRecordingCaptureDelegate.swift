//
//  RecordingCaptureDelegate.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 13.10.2020.
//

import Foundation

protocol XCRecordingCaptureDelegate: class {
    func recordingCaptureDidFinishRecordingToTmpFile(_ outputFileURL: URL)
    func recordingCaptureDidFinishWithError(_ error: Error)
    func recordingCaptureDidStartRecordingToFile(_ url: URL)
    func recordingCaptureProcessingFiles(isProcessing: Bool)
}

extension XCRecordingCaptureDelegate {
    func recordingCaptureDidStartRecordingToFile(_ url: URL) { }
    func recordingCaptureDidFinishWithError(_ error: Error) { }
    func recordingCaptureProcessingFiles(isProcessing: Bool) { }
}
