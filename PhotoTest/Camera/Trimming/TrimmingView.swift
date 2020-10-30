//
//  TrimmingView.swift
//  yourservice-ios
//
//  Created by Igor Sorokin on 27/10/2020.
//

import UIKit

final class TrimmingView: UIView {
    
    var playerView: PlayerView!
    var secondsLabel: UILabel!
    var trimmerView: TrimmerControl!
    var nextButton: BigButton!
    var playView: UIView!
    
    private var bottomView: UIView!
    private var stackView: UIStackView!
    private var playImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
        setupConstraints()
    }
    
    //MARK: - private methods
    private func setupViews() {
        
        playerView = {
            let i = PlayerView()
            i.backgroundColor = .black
            return i
        }()
        
        playView = {
            let i = UIView()
            i.backgroundColor = UIColor.black.withAlphaComponent(0.35)
            i.layer.cornerRadius = 34.5
            i.layer.masksToBounds = true
            i.isUserInteractionEnabled = false
            i.isHidden = true
            return i
        }()
        
        playImageView = {
            let i = UIImageView()
            i.image = Asset.play.image
            return i
        }()
        
        secondsLabel = {
            let i = UILabel()
            i.font = .systemFont(ofSize: 14, weight: .medium)
            i.textColor = .white
            i.textAlignment = .center
            i.text = "0:00"
            return i
        }()
        
        trimmerView = {
            let i = TrimmerControl()
            return i
        }()
        
        nextButton = {
            let i = ComponentHelper.nextButton()
            return i
        }()
        
        bottomView = {
            let i = UIView()
            i.backgroundColor = .black
            return i
        }()
        
        stackView = {
            let i = UIStackView()
            i.axis = .vertical
            return i
        }()
        
        addSubview(playerView)
        addSubview(bottomView)
        
        playerView.addSubview(playView)
        playView.addSubview(playImageView)
        bottomView.addSubview(stackView)
        
        stackView.addArrangedSubview(secondsLabel)
        stackView.addArrangedSubview(trimmerView)
        stackView.addArrangedSubview(nextButton)
    }
    
    
    private func setupConstraints() {
        stackView.setCustomSpacing(22, after: secondsLabel)
        stackView.setCustomSpacing(36, after: trimmerView)
        
        playerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomView.snp.top)
        }
        
        bottomView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(15)
            $0.leading.equalTo(20)
            $0.trailing.equalTo(-20)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-26)
        }
        
        playView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(69)
        }
        
        playImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
    }

}
