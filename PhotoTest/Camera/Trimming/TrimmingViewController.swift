//
//  TrimmingViewController.swift
//  yourservice-ios
//
//  Created by Igor Sorokin on 27/10/2020.
//

import UIKit
import AVFoundation

protocol TrimmingControllerDelegate: class {
    func trimmingControllerDidTrim(video: YSVideo, in range: YSTrimRange, newVideo: YSVideo)
}

final class TrimmingViewController: UIViewController {
    
    private final class ObsPlayer: AVPlayer {
        
        var playingHandler: ((Bool) -> Void)?
        
        override func play() {
            super.play()
            playingHandler?(true)
        }
        
        override func pause() {
            super.pause()
            playingHandler?(false)
        }
        
    }

    weak var delegate: TrimmingControllerDelegate?
    
    private weak var playerView: PlayerView!
    private weak var secondsLabel: UILabel!
    private weak var trimmerView: TrimmerControl!
    private weak var nextButton: BigButton!
    private weak var playView: UIView!
    
    private var viewModel: TrimmingViewModel!
    private var playbackObserver: Any?
    private var timerFormatter: MinutesSecondsRecordingProvider = .init()
    
    private var player: ObsPlayer {
        playerView.playerLayer.player! as! ObsPlayer
    }
    
    init(viewModel: TrimmingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("DEINIT \(self)")
    }

    //MARK: - life cicle
    override func loadView() {
        super.loadView()
        let view = TrimmingView()
        self.view = view
        playerView = view.playerView
        secondsLabel = view.secondsLabel
        trimmerView = view.trimmerView
        nextButton = view.nextButton
        playView = view.playView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }
    
    private func configureNavigationBar() {
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: nil,
            action: nil
        )
    }
    
    private func configureViews() {
        playerView.playerLayer.player = ObsPlayer(url: viewModel.video.url)
        
        player.playingHandler = { [weak self] isPlaying in
            if isPlaying {
                self?.startPlaybackObserver()
                self?.hidePlayView()
            } else {
                self?.stopPlaybackObserver()
                self?.showPlayView()
            }
        }
        
        trimmerView.delegate = self
        trimmerView.asset = AVAsset(url: viewModel.video.url)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playerTapped(_:)))
        playerView.addGestureRecognizer(tapGesture)
        
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func playerTapped(_ recognizer: UITapGestureRecognizer) {
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }
    
    @objc private func nextTapped() {
        guard
            let start = trimmerView.startTime,
            let end = trimmerView.endTime else { return }
        
        let trimRange = YSTrimRange(start: start, end: end)
        
        showHUD()
        viewModel.trimVideo(for: trimRange, completion: { [weak self] newVideo in
            guard let self = self else { return }
            self.showHUD(false)
            self.delegate?.trimmingControllerDidTrim(video: self.viewModel.video, in: trimRange, newVideo: newVideo)
        })
    }
    
    // MARK: - Helpers
    private func showPlayView() {
        guard playView.isHidden else { return }
        
        playView.isHidden = false
        playView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        
        UIView.animate(withDuration: 0.2, animations:{
            self.playView.alpha = 1
            self.playView.transform = .identity
        })
    }
    
    private func hidePlayView() {
        playView.isHidden = true
        playView.alpha = 0
    }
    
    private func startPlaybackObserver() {
        guard playbackObserver == nil else { return }
        
        playbackObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 60), queue: nil, using: { [weak self] _ in
            guard
                let self = self,
                let startTime = self.trimmerView.startTime,
                let endTime = self.trimmerView.endTime else { return }
            
            let time = self.player.currentTime()
            
            if time >= endTime {
                self.player.seek(to: startTime)
                self.trimmerView.movePositionBar(to: startTime)
                self.player.play()
            } else {
                self.trimmerView.movePositionBar(to: time)
                self.secondsLabel.text = self.timerFormatter.timeFormatted(Int(ceil(time.seconds - startTime.seconds)))
            }
        })
    }
    
    private func stopPlaybackObserver() {
        if let playbackObserver = playbackObserver {
            player.removeTimeObserver(playbackObserver)
        }
        playbackObserver = nil
    }
    
}

extension TrimmingViewController: TrimmerDelegate {
    
    func trimmerDidMove(handlerView: HandlerView) {
        if handlerView.orientation.isLeft {
            secondsLabel.text = timerFormatter.timeFormatted(0)
        } else {
            let duration = ceil(trimmerView.durationTime?.duration.seconds ?? 0)
            secondsLabel.text = timerFormatter.timeFormatted(Int(duration))
        }
    }
    
    func trimmerPositionBar(didChangePositionTo playingTime: CMTime) {
        player.pause()
        player.seek(to: playingTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func trimmerDidEndTrim() {
        player.play()
    }
    
}
