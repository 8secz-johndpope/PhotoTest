//
//  ThumbnailView.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 27.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit
import AVFoundation

class ThumbnailView: UIView {
    
    var asset: AVAsset? {
        set {
            scrollView.asset = newValue
        }
        get {
            scrollView.asset
        }
    }
    
    var maxDuration: Double {
        set {
            scrollView.maxDuration = newValue
        }
        get {
            scrollView.maxDuration
        }
    }
    
    var preferredThumbnailSize: CGSize? {
        set {
            scrollView.preferredThumbnailSize = newValue
        }
        get {
            scrollView.preferredThumbnailSize
        }
    }

    var durationSize: CGFloat {
        scrollView.contentSize.width
    }
    
    private(set) var scrollView: ThumbnailScrollView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
        configureConstraints()
    }
    
    func configureViews() {
        scrollView = {
            let i = ThumbnailScrollView()
            return i
        }()
        
        addSubview(scrollView)
    }
    
    func configureConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    // MARK: - Helpers

    func getTime(from position: CGFloat) -> CMTime? {
        guard let asset = asset else { return nil }
        
        let normalizedRatio = max(min(1, position / durationSize), 0)
        let positionTimeValue = Double(normalizedRatio) * Double(asset.duration.value)
        return CMTime(value: Int64(positionTimeValue), timescale: asset.duration.timescale)
    }
    
    func getPosition(from time: CMTime) -> CGFloat? {
        guard let asset = asset else { return nil }
        
        let timeRatio = CGFloat(time.value) * CGFloat(asset.duration.timescale) / (CGFloat(asset.duration.value) * CGFloat(time.timescale))
        return timeRatio * durationSize
    }
    
}
