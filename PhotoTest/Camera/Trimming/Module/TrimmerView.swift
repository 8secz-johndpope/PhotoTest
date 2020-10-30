//
//  TrimmerView.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 28.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit

class TrimmerView: ThumbnailView {

    let handlerWidth: CGFloat = 30
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 30)
    }
    
    private(set) var rightHandler: HandlerView!
    private(set) var leftHandler: HandlerView!
    private(set) var positionBar: UIView!
    private var topHandlerLine: UIView!
    private var bottomHandlerLine: UIView!
    private var rightMaskView: UIView!
    private var leftMaskView: UIView!
    
    private(set) var leftHandlerConstraint: NSLayoutConstraint!
    private(set) var rightHandlerConstraint: NSLayoutConstraint!
    private(set) var barConstraint: NSLayoutConstraint!
    
    override func configureViews() {
        super.configureViews()
        
        rightHandler = {
            let i = HandlerView(orientation: .right, frame: .zero)
            return i
        }()
        
        leftHandler = {
            let i = HandlerView(orientation: .left, frame: .zero)
            return i
        }()
        
        topHandlerLine = {
            let i = UIView()
            i.backgroundColor = .white
            return i
        }()
        
        bottomHandlerLine = {
            let i = UIView()
            i.backgroundColor = .white
            return i
        }()
        
        rightMaskView = {
            let i = UIView()
            i.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            return i
        }()
        
        leftMaskView = {
            let i = UIView()
            i.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            return i
        }()
        
        positionBar = {
            let i = UIView(frame: .zero)
            i.backgroundColor = .black
            i.layer.cornerRadius = 1.5
            i.layer.masksToBounds = true
            return i
        }()
        
        addSubview(leftMaskView)
        addSubview(rightMaskView)
        
        addSubview(topHandlerLine)
        addSubview(bottomHandlerLine)
        
        addSubview(leftHandler)
        addSubview(rightHandler)
        
        addSubview(positionBar)
    }
    
    override func configureConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets().left(handlerWidth).right(handlerWidth))
        }
        
        leftMaskView.snp.makeConstraints {
            $0.top.equalTo(0)
            $0.bottom.equalTo(0)
            $0.leading.equalTo(0)
            $0.trailing.equalTo(leftHandler.snp.trailing)
        }
        
        rightMaskView.snp.makeConstraints {
            $0.top.equalTo(0)
            $0.bottom.equalTo(0)
            $0.trailing.equalTo(0)
            $0.leading.equalTo(rightHandler.snp.leading)
        }
        
        topHandlerLine.snp.makeConstraints {
            $0.top.equalTo(0)
            $0.height.equalTo(2)
            $0.leading.equalTo(leftHandler.snp.trailing)
            $0.trailing.equalTo(rightHandler.snp.leading)
        }
        
        bottomHandlerLine.snp.makeConstraints {
            $0.bottom.equalTo(0)
            $0.height.equalTo(2)
            $0.leading.equalTo(leftHandler.snp.trailing)
            $0.trailing.equalTo(rightHandler.snp.leading)
        }
        
        leftHandler.translatesAutoresizingMaskIntoConstraints = false
        leftHandler.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftHandler.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftHandler.widthAnchor.constraint(equalToConstant: handlerWidth).isActive = true
        leftHandlerConstraint = leftHandler.leadingAnchor.constraint(equalTo: leadingAnchor)
        leftHandlerConstraint.isActive = true
        
        rightHandler.translatesAutoresizingMaskIntoConstraints = false
        rightHandler.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightHandler.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        rightHandler.widthAnchor.constraint(equalToConstant: handlerWidth).isActive = true
        rightHandlerConstraint = rightHandler.trailingAnchor.constraint(equalTo: trailingAnchor)
        rightHandlerConstraint.isActive = true
        
        positionBar.translatesAutoresizingMaskIntoConstraints = false
        positionBar.topAnchor.constraint(equalTo: topAnchor, constant: 1).isActive = true
        positionBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1).isActive = true
        positionBar.widthAnchor.constraint(equalToConstant: 3).isActive = true
        barConstraint = positionBar.leadingAnchor.constraint(equalTo: leftHandler.trailingAnchor)
        barConstraint.isActive = true
    }
    
}
