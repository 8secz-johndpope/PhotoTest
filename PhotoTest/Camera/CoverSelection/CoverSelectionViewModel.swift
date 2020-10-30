//
//  CoverSelectionViewModel.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 29.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit
import AVFoundation

protocol CoverSelectionViewModel {
    var video: YSVideo { get }
    func extractCover(at selectedTime: CMTime, completion: @escaping (YSVideo, YSCover) -> Void)
}

final class CoverSelectionViewModelImp: CoverSelectionViewModel {

    var video: YSVideo
    
    private lazy var generator: AVAssetImageGenerator = .init(asset: AVAsset(url: video.url))
    
    init(video: YSVideo) {
        self.video = video
    }
    
    deinit {
        print("DEINIT \(self)")
    }
    
    func extractCover(at selectedTime: CMTime, completion: @escaping (YSVideo, YSCover) -> Void) {
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: selectedTime)], completionHandler: { [weak self] _, cgImage, _, _, _ in
            guard
                let self = self,
                let cgImage = cgImage else { return }
            
            let asset = AVAsset(url: self.video.url)
            let videoTrack = asset.tracks(withMediaType: .video).first
            let orientation = videoTrack?.preferredTransform.cgImageOrientation()
            
            let ciImage = CIImage(cgImage: cgImage).oriented(orientation ?? .right)
            
            self.video.cover = ciImage
            DispatchQueue.main.async {
                completion(self.video, ciImage)
            }
        })
    }
    
}
