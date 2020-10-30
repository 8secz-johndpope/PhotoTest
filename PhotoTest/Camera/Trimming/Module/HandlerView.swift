//
//  HandlerView.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 28.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit

class HandlerView: UIView {
    
    enum Orientation {
        case right
        case left
        
        var isLeft: Bool {
            self == .left
        }
    }
    
    var orientation: Orientation = .left
    
    private var imageView: UIImageView!
    
    init(orientation: Orientation, frame: CGRect) {
        super.init(frame: frame)
        self.orientation = orientation
        configureViews()
        configureConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
        configureConstraints()
    }

    private func configureViews() {
        backgroundColor = .white
        layer.maskedCorners = orientation.isLeft ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight]
        layer.cornerRadius = 5
        
        imageView = {
            let i = UIImageView()
            i.image = orientation.isLeft ? Asset.leftHandle.image : Asset.rightHandle.image
            return i
        }()
        
        addSubview(imageView)
    }
    
    private func configureConstraints() {
        imageView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
}
