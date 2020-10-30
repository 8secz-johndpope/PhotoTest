//
//  CSelectionView.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 28.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit

class ThumbSelectionView: ThumbnailView {
    
    private var dimmingView: UIView!
    private var thumbView: UIImageView!
    
    private(set) var thumbConstraint: NSLayoutConstraint!
    
    override func configureViews() {
        super.configureViews()
        
        dimmingView = {
            let i = UIView()
            i.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            return i
        }()
        
        thumbView = {
            let i = UIImageView()
            i.contentMode = .scaleAspectFill
            i.layer.borderWidth = 2
            i.layer.borderColor = UIColor.white.cgColor
            return i
        }()
        
        addSubview(dimmingView)
        addSubview(thumbView)
    }
    
    override func configureConstraints() {
        super.configureConstraints()
        
        dimmingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        thumbView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        thumbView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        thumbView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        thumbView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        thumbConstraint = thumbView.leadingAnchor.constraint(equalTo: leadingAnchor)
        thumbConstraint.isActive = true
    }
    
}
