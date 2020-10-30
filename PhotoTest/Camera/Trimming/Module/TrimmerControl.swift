//
//  TrimmerControl.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 28.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit
import AVFoundation

protocol TrimmerDelegate: class {
    func trimmerDidMove(handlerView: HandlerView)
    func trimmerPositionBar(didChangePositionTo playingTime: CMTime)
    func trimmerDidEndTrim()
}

class TrimmerControl: TrimmerView {

    weak var delegate: TrimmerDelegate?
    
    var startTime: CMTime? {
        let startPosition = leftHandler.frame.origin.x + scrollView.contentOffset.x
        return getTime(from: startPosition)
    }

    var endTime: CMTime? {
        let endPosition = rightHandler.frame.origin.x + scrollView.contentOffset.x - handlerWidth
        return getTime(from: endPosition)
    }
    
    var positionBarTime: CMTime? {
        let barPosition = positionBar.frame.origin.x + scrollView.contentOffset.x - handlerWidth
        return getTime(from: barPosition)
    }
    
    var durationTime: CMTimeRange? {
        guard let endTime = endTime, let startTime = startTime else { return nil }
        return CMTimeRange(start: startTime, end: endTime)
    }
    
    private let minimumDistanceBetweenHandle: CGFloat = 30
    private var leftConstraintConstant: CGFloat = 0
    private var rightConstraintConstant: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupRecognizers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRecognizers()
    }
    
    func movePositionBar(to time: CMTime) {
        guard let newPosition = getPosition(from: time) else { return }
        
        let offsetPosition = newPosition - scrollView.contentOffset.x - leftHandler.frame.origin.x
        let maxPosition = rightHandler.frame.origin.x - (leftHandler.frame.origin.x + handlerWidth) - positionBar.frame.width / 2
        let normalizedPosition = min(max(0, offsetPosition), maxPosition)
        barConstraint?.constant = normalizedPosition
        layoutIfNeeded()
    }
    
    private func setupRecognizers() {
        let leftGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanning(_:)))
        let rightGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanning(_:)))
        
        leftHandler.addGestureRecognizer(leftGesture)
        rightHandler.addGestureRecognizer(rightGesture)
    }
    
    @objc private func handlePanning(_ recognizer: UIPanGestureRecognizer) {
        guard let view = recognizer.view else { return }
        let isLeftHandler = (view == leftHandler)
        
        switch recognizer.state {
        case .began:
            if isLeftHandler {
                leftConstraintConstant = leftHandlerConstraint?.constant ?? 0
            } else {
                rightConstraintConstant = rightHandlerConstraint?.constant ?? 0
            }
            updateSelectedTime()
        case .changed:
            let translation = recognizer.translation(in: view)
            if isLeftHandler {
                updateLeftConstraint(with: translation)
            } else {
                updateRightConstraint(with: translation)
            }
            layoutIfNeeded()
            
            if let startTime = startTime, isLeftHandler {
                movePositionBar(to: startTime)
            } else if let endTime = endTime {
                movePositionBar(to: endTime)
            }
            updateSelectedTime()
            delegate?.trimmerDidMove(handlerView: isLeftHandler ? leftHandler : rightHandler)
            
        case .cancelled, .ended, .failed:
            updateSelectedTime()
            delegate?.trimmerDidEndTrim()
            
        default:
            break
        }
    }
    
    private func updateLeftConstraint(with translation: CGPoint) {
        let maxConstraint = max(rightHandler.frame.origin.x - handlerWidth - minimumDistanceBetweenHandle, 0)
        let newConstraint = min(max(0, leftConstraintConstant + translation.x), maxConstraint)
        leftHandlerConstraint?.constant = newConstraint
    }

    private func updateRightConstraint(with translation: CGPoint) {
        let maxConstraint = min(2 * handlerWidth - frame.width + leftHandler.frame.origin.x + minimumDistanceBetweenHandle, 0)
        let newConstraint = max(min(0, rightConstraintConstant + translation.x), maxConstraint)
        rightHandlerConstraint?.constant = newConstraint
    }
    
    private func updateSelectedTime() {
        guard let playerTime = positionBarTime else { return }
        delegate?.trimmerPositionBar(didChangePositionTo: playerTime)
    }
    
}
