//
//  CameraFactory.swift
//  yourservice-ios
//
//  Created by Igor Sorokin on 26/10/2020.
//

import UIKit

final class CameraFactory: SceneFactory {
    
    private let options: CameraOptions
    
    init(options: CameraOptions) {
        self.options = options
    }
    
    func makeViewModel() -> CameraViewModel {
        #if MOCK
        return  CameraViewModelImp()
        #else
        return  CameraViewModelImp()
        #endif
    }
    
    func makeViewController() -> CameraViewController {
        return CameraViewController(options: options, viewModel: self.makeViewModel())
    }
}
