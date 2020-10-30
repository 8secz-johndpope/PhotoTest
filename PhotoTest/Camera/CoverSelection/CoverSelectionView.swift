//
//  CoverSelectionView.swift
//  yourservice-ios
//
//  Created by Igor Sorokin on 28/10/2020.
//

import UIKit

final class CoverSelectionView: UIView {
    
    var playerView: PlayerView!
    var selectionControl: ThumbSelectionControl!
    var nextButton: BigButton!
    
    private var coverLabel: UILabel!
    private var bottomView: UIView!
    private var stackView: UIStackView!
    
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
        
        coverLabel = {
            let i = UILabel()
            i.font = .systemFont(ofSize: 14, weight: .medium)
            i.textColor = .white
            i.textAlignment = .center
            i.text = L10n.Camera.chooseCover
            return i
        }()
        
        selectionControl = {
            let i = ThumbSelectionControl()
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
        
        bottomView.addSubview(stackView)
        
        stackView.addArrangedSubview(coverLabel)
        stackView.addArrangedSubview(selectionControl)
        stackView.addArrangedSubview(nextButton)
    }
    
    
    private func setupConstraints() {
        stackView.setCustomSpacing(22, after: coverLabel)
        stackView.setCustomSpacing(15, after: selectionControl)
        
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
        
    }


}
