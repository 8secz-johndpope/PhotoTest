//
//  CoverSelectionFactory.swift
//  yourservice-ios
//
//  Created by Igor Sorokin on 28/10/2020.
//

import UIKit

final class CoverSelectionFactory: SceneFactory {

    private let video: YSVideo
    
    init(video: YSVideo) {
        self.video = video
    }
    
    func makeViewModel() -> CoverSelectionViewModel {
        #if MOCK
        return  CoverSelectionViewModelImp(video: video)
        #else
        return  CoverSelectionViewModelImp(video: video)
        #endif
    }
    
    func makeViewController() -> CoverSelectionViewController {
        return CoverSelectionViewController(viewModel: self.makeViewModel())
    }
}
