//
//  ExposureView.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 22.10.2020.
//

import UIKit

class ExposureView: UIView {

    private var lightView: ExposureLightView?
    
    private var lineLayer: CAShapeLayer?
    private(set) var maskLayer: CAShapeLayer?
    
    private(set) var lightYConstraint: NSLayoutConstraint?
    
    private var maskRect: CGRect {
        let origin = CGPoint(x: bounds.midX - 18, y: bounds.midY - 18)
        let size = CGSize(width: 36, height: 36)
        return CGRect(origin: origin, size: size)
    }
    
    private var lineStartPoint: CGPoint {
        CGPoint(x: bounds.midX, y: bounds.minY)
    }
    
    private var lineEndPoint: CGPoint {
        CGPoint(x: bounds.midX, y: bounds.maxY)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if lineLayer == nil, lightView == nil {
            configureViews()
            configureLightConstraints()
        }
    }
    
    private func configureViews() {
        let linePath: UIBezierPath = {
            let i = UIBezierPath()
            i.move(to: lineStartPoint)
            i.addLine(to: lineEndPoint)
            i.lineWidth = 2
            return i
        }()
        
        lineLayer = {
            let i = CAShapeLayer()
            i.path = linePath.cgPath
            i.strokeColor = UIColor(red: 244/255, green: 222/255, blue: 89/255, alpha: 1).cgColor
            i.lineCap = .round
            return i
        }()
        
        lightView = {
            let i = ExposureLightView()
            return i
        }()
        
        let cirlePath1: CGMutablePath = {
            let i = CGMutablePath()
            i.addRect(bounds)
            i.addRect(maskRect)
            return i
        }()
        
        maskLayer = {
            let i = CAShapeLayer()
            i.path = cirlePath1
            i.fillRule = .evenOdd
            return i
        }()
        
        addSubview(lightView!)
        layer.addSublayer(lineLayer!)
        
        lineLayer?.mask = maskLayer
    }

    private func configureConstraints() {
        snp.makeConstraints {
            $0.width.equalTo(15)
        }
    }
    
    private func configureLightConstraints() {
        lightView?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        lightYConstraint = lightView?.centerYAnchor.constraint(equalTo: centerYAnchor)
        lightYConstraint?.isActive = true
    }
    
}
