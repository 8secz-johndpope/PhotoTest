//
//  CameraCoordinator.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 29.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit

class CameraCoordinator {
    
    var completion: ((YSMedia?) -> Void)?

    private let viewController: UIViewController
    private let cameraOptions: CameraOptions
    private var navigation: UINavigationController?
    
    init(viewController: UIViewController, cameraOptions: CameraOptions) {
        self.viewController = viewController
        self.cameraOptions = cameraOptions
    }
    
    func present() {
        navigation = UINavigationController(rootViewController: makeCamera())
        navigation?.modalPresentationStyle = .fullScreen
        viewController.present(navigation!, animated: true)
    }
    
    func close() {
        viewController.dismiss(animated: true)
        navigation = nil
    }
    
    // MARK: - Helpers
    private func makeCamera() -> UIViewController {
        let camera = CameraFactory(options: cameraOptions).makeViewController()
        camera.delegate = self
        return camera
    }
    
    private func makeTrimmer(for video: YSVideo) -> UIViewController {
        let trimmer = TrimmingFactory(video: video).makeViewController()
        trimmer.delegate = self
        return trimmer
    }
    
    private func makeCover(for video: YSVideo) -> UIViewController {
        let cover = CoverSelectionFactory(video: video).makeViewController()
        cover.delegate = self
        return cover
    }
    
}

extension CameraCoordinator: CameraControllerDelegate {
    
    func cameraControllerDidCapture(ysPhoto: YSPhoto) {
        completion?(ysPhoto)
        close()
    }
    
    func cameraControllerDidRecording(ysVideo: YSVideo) {
        let trimmer = makeTrimmer(for: ysVideo)
        navigation?.pushViewController(trimmer, animated: true)
    }
    
    func cameraControllerPermissionFailed() {
        completion?(nil)
        close()
    }
    
}

extension CameraCoordinator: TrimmingControllerDelegate {
    
    func trimmingControllerDidTrim(video: YSVideo, in range: YSTrimRange, newVideo: YSVideo) {
        let cover = makeCover(for: newVideo)
        navigation?.pushViewController(cover, animated: true)
    }
    
}

extension CameraCoordinator: CoverSelectionControllerDelegate {
    
    func coverSelectionDidSelectCover(for video: YSVideo, cover: YSCover) {
        completion?(video)
        close()
    }
    
}
