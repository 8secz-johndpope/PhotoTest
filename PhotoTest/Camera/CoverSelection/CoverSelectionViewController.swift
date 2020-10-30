//
//  CoverSelectionViewController.swift
//  yourservice-ios
//
//  Created by Igor Sorokin on 28/10/2020.
//

import UIKit
import AVFoundation

protocol CoverSelectionControllerDelegate: class {
    func coverSelectionDidSelectCover(for video: YSVideo, cover: YSCover)
}

final class CoverSelectionViewController: UIViewController {

    weak var delegate: CoverSelectionControllerDelegate?
    
    private weak var playerView: PlayerView!
    private weak var selectionControl: ThumbSelectionControl!
    private weak var nextButton: BigButton!
    
    private var viewModel: CoverSelectionViewModel!
    
    private var player: AVPlayer {
        playerView.playerLayer.player!
    }
    
    init(viewModel: CoverSelectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("DEINIT \(self)")
    }
    
    override func loadView() {
        super.loadView()
        let view = CoverSelectionView()
        self.view = view
        playerView = view.playerView
        selectionControl = view.selectionControl
        nextButton = view.nextButton
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    private func configureViews() {
        playerView.playerLayer.player = AVPlayer(url: viewModel.video.url)
        
        selectionControl.delegate = self
        selectionControl.asset = AVAsset(url: viewModel.video.url)
        
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
    
    @objc private func nextTapped() {
        guard let selectedTime = selectionControl.selectedTime else { return }
        
        self.showHUD()
        viewModel.extractCover(at: selectedTime, completion: { [weak self] video, cover in
            self?.showHUD(false)
            self?.delegate?.coverSelectionDidSelectCover(for: video, cover: cover)
        })
    }

}

extension CoverSelectionViewController: ThumbSelectionDelegate {
    
    func thumbSelectionDidSelectCover(at time: CMTime) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
}
