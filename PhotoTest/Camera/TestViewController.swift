//
//  TestViewController.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 29.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit
import AVFoundation

class TestViewController: UIViewController {

    var imageView: UIImageView!
    var playerLayer: PlayerView!
    var button: UIButton!
    
    var coord: CameraCoordinator!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        
        playerLayer = PlayerView()
        
        button = UIButton()
        button.setTitle("Open camera", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(tap), for: .touchUpInside)
        
        view.addSubview(imageView)
        view.addSubview(playerLayer)
        view.addSubview(button)
        
        imageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(200)
        }
        
        playerLayer.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(300)
        }
        
        button.snp.makeConstraints {
            $0.top.equalTo(playerLayer.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(20)
        }
    }
    
    @objc private func tap() {
        coord = CameraCoordinator(viewController: self, cameraOptions: [.photo, .video])
        coord.completion = { media in
            switch media {
            case let photo as YSPhoto:
                self.imageView.image = UIImage(ciImage: photo.image)
                print("IMAGE BOUNDS: \(photo.bounds)")
                print("IMAGE DATE: \(photo.date)")
                
            case let video as YSVideo:
                self.imageView.image = UIImage(ciImage: video.cover!)
                self.playerLayer.playerLayer.player = AVPlayer(url: video.url)
                self.playerLayer.playerLayer.player?.play()
                print("VIDEO DIURATION: \(video.duration)")
                print("VIDEO DATE: \(video.date)")
                print("VIDEO SIZE: \(video.fileSize)")
                
            default:
                print("ERROR")
            }
        }
        
        coord.present()
    }
    
}
