//
//  ThumbSelectionControl.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 28.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit
import AVFoundation

protocol ThumbSelectionDelegate: class {
    func thumbSelectionDidSelectCover(at time: CMTime)
}

class ThumbSelectionControl: ThumbSelectionView {
    
    weak var delegate: ThumbSelectionDelegate?
    
    override var asset: AVAsset? {
        didSet {
            assetDidChange()
        }
    }
    
    private var currentThumbConstant: CGFloat = 0
    private var generator: AVAssetImageGenerator!
    
    var selectedTime: CMTime? {
        let thumbPosition = thumbView.frame.origin.x + scrollView.contentOffset.x
        return getTime(from: thumbPosition)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupRecognizers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRecognizers()
    }
    
    private func setupRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(thumbPanned(_:)))
        thumbView.isUserInteractionEnabled = true
        thumbView.addGestureRecognizer(panGesture)
    }
    
    @objc private func thumbPanned(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            currentThumbConstant = thumbConstraint.constant
            updateSelection()
            
        case .changed:
            let translation = recognizer.translation(in: thumbView)
            updateThumbConstraint(with: translation)
            updateSelection()
            
        case .ended, .cancelled, .failed:
            updateSelection()
            
        default:
            break
        }
    }
    
    private func assetDidChange() {
        guard let asset = asset else { return }
        setupThumbnailGenerator(with: asset)
        thumbConstraint.constant = 0
        generateThumbnailImage(for: selectedTime ?? .zero)
    }
    
    private func setupThumbnailGenerator(with asset: AVAsset) {
        generator = AVAssetImageGenerator(asset: asset)
        generator?.appliesPreferredTrackTransform = true
        generator?.requestedTimeToleranceAfter = CMTime.zero
        generator?.requestedTimeToleranceBefore = CMTime.zero
    }
    
    private func updateThumbConstraint(with translation: CGPoint) {
        let maxConstraint = frame.width - thumbView.frame.width
        let newConstraint = min(max(0, currentThumbConstant + translation.x), maxConstraint)
        thumbConstraint?.constant = newConstraint
    }
    
    private func updateSelection() {
        guard let selectedTime = selectedTime else { return }
        generateThumbnailImage(for: selectedTime)
        delegate?.thumbSelectionDidSelectCover(at: selectedTime)
    }
    
    private func generateThumbnailImage(for time: CMTime) {
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)], completionHandler: { [weak self] _, cgImage, _, _, _ in
            guard let cgImage = cgImage else { return }
            
            DispatchQueue.main.async {
                self?.generator.cancelAllCGImageGeneration()
                self?.thumbView.image = UIImage(cgImage: cgImage)
            }
        })
    }
    
}
