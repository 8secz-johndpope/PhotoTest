//
//  VideoTimer.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 19.10.2020.
//

import UIKit

protocol RecordingTimerDisplayProvider {
    func timeFormatted(_ totalSeconds: Int) -> String
}

final class MinutesSecondsRecordingProvider: RecordingTimerDisplayProvider {
    func timeFormatted(_ totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        return String(format: "%01d:%02d", minutes, seconds)
    }
}

final class RecordingTimer {
    
    var displayProvider: RecordingTimerDisplayProvider
    var totalSeconds: Int = 60
    var initialSeconds: Int = 0 {
        didSet {
            currentSecond = initialSeconds
        }
    }
    
    var progress: Float {
        Float(currentSecond) / Float(totalSeconds)
    }
    
    private lazy var currentSecond: Int = initialSeconds
    private var timer: Timer?
    private let displayHandler: (RecordingTimer, String) -> Void
    private let endHandler: () -> Void
    
    init(
        displayProvider: RecordingTimerDisplayProvider,
        displayHandler: @escaping (RecordingTimer, String) -> Void,
        endHandler: @escaping () -> Void
    ) {
        self.displayProvider = displayProvider
        self.displayHandler = displayHandler
        self.endHandler = endHandler
    }
    
    deinit {
        print("DEINIT \(self)")
        invalidate()
    }
    
    func startTimer() {
        guard initialSeconds < totalSeconds else { return }
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    func invalidate() {
        timer?.invalidate()
        timer = nil
        currentSecond = 0
    }
    
    @objc private func updateTime() {
        if currentSecond == totalSeconds {
            endHandler()
            invalidate()
        } else {
            currentSecond += 1
            displayHandler(self, displayProvider.timeFormatted(currentSecond))
        }
    }
    
}
