//
//  ThumbnailScrollView.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 27.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit
import AVFoundation

class ThumbnailScrollView: UIScrollView {

    var asset: AVAsset? {
        didSet {
            needsUpdate = true
            setNeedsLayout()
        }
    }
    
    var preferredThumbnailSize: CGSize?
    var maxDuration: Double = Double(Constants.CameraSettings.videoDuration)
    
    private var needsUpdate: Bool = false
    private var generator: AVAssetImageGenerator?
    
    private var contentView: UIView!
    private var widthConstraint: NSLayoutConstraint!
    
    private var parentSize: CGSize {
        superview?.frame.size ?? .zero
    }
    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentSize = contentView.bounds.size
        
        guard
            needsUpdate,
            let asset = asset,
            parentSize.width > 0,
            parentSize.height > 0 else { return }
        
        needsUpdate = false
        generateThumbnails(for: asset)
    }
    
    func generateThumbnails(for asset: AVAsset) {
        guard let thumbnailSize = getThumbnailSize(from: asset), thumbnailSize.width != 0 else {
            print("\(#function)\nWarning: can't get thumbnail size")
            return
        }
        
        generator?.cancelAllCGImageGeneration()
        removeThumbnails()
        
        let newContentSize = getContentSize(for: asset)
        let visibleThumbnailsCount = Int(ceil(frame.width / thumbnailSize.width))
        let thumbnailCount = Int(ceil(newContentSize.width / thumbnailSize.width))
        let timesForThumbnail = getThumbnailTimes(for: asset, numberOfThumbnails: thumbnailCount)
        
        addThumbnailViews(thumbnailCount, size: thumbnailSize)
        generateImages(for: asset, at: timesForThumbnail, with: thumbnailSize, visibleThumnails: visibleThumbnailsCount)
    }
    
}

// MARK: - Helpers -
private extension ThumbnailScrollView {
    
    func getThumbnailSize(from asset: AVAsset) -> CGSize? {
        if let preferredThumbnailSize = preferredThumbnailSize {
            return preferredThumbnailSize
        }
        
        guard let track = asset.tracks(withMediaType: .video).first else { return nil }
        
        let assetSize = track.naturalSize.applying(track.preferredTransform)
        let ratio = assetSize.width / assetSize.height
        let height = parentSize.height
        let width = height * ratio
        return CGSize(width: abs(width), height: abs(height))
    }
    
    func getContentSize(for asset: AVAsset) -> CGSize {
        let contentWidthFactor = CGFloat(max(1, asset.duration.seconds / maxDuration))
        widthConstraint.isActive = false
        
        widthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: contentWidthFactor)
        widthConstraint.isActive = true
        layoutIfNeeded()
        
        return contentView.bounds.size
    }
    
    func addThumbnailViews(_ count: Int, size: CGSize) {
        (0 ..< count).forEach { index in
            let thumbnailView = UIImageView(frame: CGRect.zero)
            thumbnailView.clipsToBounds = true
            thumbnailView.contentMode = .scaleAspectFill

            let viewEndX = CGFloat(index) * size.width + size.width

            if viewEndX > contentView.frame.width {
                thumbnailView.frame.size = CGSize(width: size.width + (contentView.frame.width - viewEndX), height: size.height)
            } else {
                thumbnailView.frame.size = size
            }

            thumbnailView.frame.origin = CGPoint(x: CGFloat(index) * size.width, y: 0)
            thumbnailView.tag = index
            contentView.addSubview(thumbnailView)
        }
    }
    
    func getThumbnailTimes(for asset: AVAsset, numberOfThumbnails: Int) -> [NSValue] {
        let timeIncrement = (asset.duration.seconds * 600) / Double(numberOfThumbnails)
        var timesForThumbnails: [NSValue] = []
        
        (0 ..< numberOfThumbnails).forEach { index in
            let cmTime = CMTime(value: Int64(timeIncrement * Float64(index)), timescale: 600)
            let value = NSValue(time: cmTime)
            timesForThumbnails.append(value)
        }
        
        return timesForThumbnails
    }
    
    func generateImages(for asset: AVAsset, at times: [NSValue], with maximumSize: CGSize, visibleThumnails: Int) {
        generator = AVAssetImageGenerator(asset: asset)
        generator?.appliesPreferredTrackTransform = true

        let scaledSize = CGSize(width: maximumSize.width * UIScreen.main.scale, height: maximumSize.height * UIScreen.main.scale)
        generator?.maximumSize = scaledSize
        var count = 0

        let handler: AVAssetImageGeneratorCompletionHandler = { [weak self] (_, cgimage, _, result, error) in
            if let cgimage = cgimage, error == nil && result == AVAssetImageGenerator.Result.succeeded {
                DispatchQueue.main.async(execute: { [weak self] () -> Void in

                    if count == 0 {
                        self?.displayFirstImage(cgimage, visibleThumbnails: visibleThumnails)
                    }
                    self?.displayImage(cgimage, at: count)
                    count += 1
                })
            }
        }

        generator?.generateCGImagesAsynchronously(forTimes: times, completionHandler: handler)
    }

    func displayFirstImage(_ cgImage: CGImage, visibleThumbnails: Int) {
        for i in 0...visibleThumbnails {
            displayImage(cgImage, at: i)
        }
    }

    func displayImage(_ cgImage: CGImage, at index: Int) {
        if let imageView = contentView.viewWithTag(index) as? UIImageView {
            let uiimage = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImage.Orientation.up)
            imageView.image = uiimage
        }
    }
    
    func removeThumbnails() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
    }
    
}


// MARK: - UI -
private extension ThumbnailScrollView {
    
    func configureViews() {
        backgroundColor = .clear
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        clipsToBounds = true
        
        contentView = {
            let i = UIView()
            i.translatesAutoresizingMaskIntoConstraints = false
            i.backgroundColor = .clear
            i.tag = -1
            return i
        }()
        
        addSubview(contentView)
    }
    
    func configureConstraints() {
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        widthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor)
        widthConstraint.isActive = true
    }
    
}
