//
//  RecordGestureRecognizer.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 13.10.2020.
//

import UIKit.UIGestureRecognizerSubclass

final class RecordGestureRecognizer: UIGestureRecognizer {
    
    // MARK: - Private properties
    private let timeout: Int
    private var timeoutWorkitem: DispatchWorkItem?
    private var trackingTouch: UITouch?
    
    // MARK: - init
    init(target: Any?, action: Selector?, timeout: Int) {
        self.timeout = timeout
        super.init(target: target, action: action)
    }
    
    // MARK: - Public methods
    func translation(in view: UIView) -> CGPoint? {
        trackingTouch?.location(in: view)
    }
    
    // MARK: - Overrides
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let trackingTouch = trackingTouch {
            touches.filter { $0 !== trackingTouch }.forEach { ignore($0, for: event) }
            state = .began
        } else if let touch = touches.first {
            trackingTouch = touch
            startTimeout()
            state = .began
        } else {
            state = .failed
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .changed
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        removeTouch(touches, stateTo: .cancelled)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        removeTouch(touches, stateTo: .ended)
    }
    
    override func reset() {
        timeoutWorkitem?.cancel()
        timeoutWorkitem = nil
        trackingTouch = nil
        state = .possible
    }
    
    // MARK: - Private methods
    private func startTimeout() {
        timeoutWorkitem = DispatchWorkItem(block: { [weak self] in
            guard let trackingTouch = self?.trackingTouch else { return }
            self?.removeTouch(Set([trackingTouch]), stateTo: .ended)
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(timeout), execute: timeoutWorkitem!)
    }
    
    private func removeTouch(_ touches: Set<UITouch>, stateTo state: UIGestureRecognizer.State) {
        guard touches.contains(where: { $0 === trackingTouch }) && (self.state == .began || self.state == .changed)  else { return }
        self.state = state
        reset()
    }
    
}
