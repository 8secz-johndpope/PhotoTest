//
//  TrimmingFactory.swift
//  yourservice-ios
//
//  Created by Igor Sorokin on 27/10/2020.
//

import UIKit

final class TrimmingFactory: SceneFactory {
    
    private let video: YSVideo
    
    init(video: YSVideo) {
        self.video = video
    }
    
    func makeViewModel() -> TrimmingViewModel {
        #if MOCK
        return  TrimmingViewModelImp(video: video)
        #else
        return  TrimmingViewModelImp(video: video)
        #endif
    }
    
    func makeViewController() -> TrimmingViewController {
        return TrimmingViewController(viewModel: self.makeViewModel())
    }
}
