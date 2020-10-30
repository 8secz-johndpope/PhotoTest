//
//  TrimmingViewModel.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 29.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import AVFoundation

protocol TrimmingViewModel {
    var video: YSVideo { get }
    func trimVideo(for range: YSTrimRange, completion: @escaping (YSVideo) -> Void)
}

final class TrimmingViewModelImp: TrimmingViewModel {

    var video: YSVideo
    
    init(video: YSVideo) {
        self.video = video
    }
    
    deinit {
        print("DEINIT \(self)")
    }
    
    func trimVideo(for range: YSTrimRange, completion: @escaping (YSVideo) -> Void) {
        let video = self.video.copy()
        let outputURL = URL.generateFileURL(type: .mp4)
        let asset = AVAsset(url: video.url)
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = outputURL
        exporter?.outputFileType = .mp4
        exporter?.timeRange = range
        
        exporter?.exportAsynchronously(completionHandler: {
            let fileAttributes = try? FileManager.default.attributesOfItem(atPath: outputURL.path)
            let fileSize = fileAttributes?[FileAttributeKey.size] as? Int64
            
            video.url = outputURL
            video.duration = range.duration.seconds
            video.fileSize = fileSize
            
            DispatchQueue.main.async {
                completion(video)
            }
        })
    }
    
}
