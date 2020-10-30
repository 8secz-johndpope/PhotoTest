//
//  YSVideo.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 26.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit
import AVFoundation

/// Mark protocol for ys media
protocol YSMedia { }

typealias YSCover = CIImage
typealias YSTrimRange = CMTimeRange

class YSVideo: YSMedia {
    var url: URL
    var duration: Float64
    var fileSize: Int64?
    var codec: AVVideoCodecType?
    var bounds: CGSize?
    var cover: YSCover?
    let date: Date
    
    init(
        url: URL,
        duration: Float64,
        fileSize: Int64? = nil,
        codec: AVVideoCodecType? = nil,
        bounds: CGSize? = nil,
        cover: YSCover? = nil,
        date: Date
    ) {
        self.url = url
        self.duration = duration
        self.fileSize = fileSize
        self.codec = codec
        self.bounds = bounds
        self.date = date
    }
    
    deinit {
        cleanup()
    }
    
    func cleanup() {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(atPath: url.path)
                print("YSVIDEO DID REMOVE FILE AT: \(url)")
            } catch {
                print("Could not remove file at url: \(url)")
            }
        }
    }
    
    func copy() -> YSVideo {
        return YSVideo(
            url: url,
            duration: duration,
            fileSize: fileSize,
            codec: codec,
            bounds: bounds,
            cover: cover,
            date: date)
    }
}
