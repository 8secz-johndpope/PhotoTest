//
//  ExposureLightView.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 22.10.2020.
//

import UIKit

class ExposureLightView: UIView {

    private var replicatorLayer: CAReplicatorLayer?
    private var rayLayer: CAShapeLayer?
    private var circleLayer: CAShapeLayer?
    
    private var rayRect: CGRect {
        let origin = CGPoint(x: bounds.midX - 0.5, y: bounds.minY)
        let size = CGSize(width: 1, height: 5)
        return CGRect(origin: origin, size: size)
    }
    
    private var circleRect: CGRect {
        let origin = CGPoint(x: bounds.midX - 4, y: bounds.midY - 4)
        let size = CGSize(width: 8, height: 8)
        return CGRect(origin: origin, size: size)
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
        if replicatorLayer == nil, rayLayer == nil, circleLayer == nil {
            configureViews()
        }
    }
    
    private func configureViews() {
        let cirlePath: UIBezierPath = {
            let i = UIBezierPath(ovalIn: circleRect)
            i.lineWidth = 1
            return i
        }()
        
        circleLayer = {
            let i = CAShapeLayer()
            i.path = cirlePath.cgPath
            i.fillColor = UIColor(red: 244/255, green: 222/255, blue: 89/255, alpha: 1).cgColor
            return i
        }()

        
        let rayPath: UIBezierPath = {
            let i = UIBezierPath(rect: rayRect)
            return i
        }()
        
        rayLayer = {
            let i = CAShapeLayer()
            i.path = rayPath.cgPath
            i.fillColor = UIColor(red: 244/255, green: 222/255, blue: 89/255, alpha: 1).cgColor
            return i
        }()
        
        replicatorLayer = {
            let i = CAReplicatorLayer()
            i.frame = bounds
            
            let angle = -(CGFloat.pi) * 2 / 8.0
            i.instanceTransform = CATransform3DMakeRotation(angle, 0, 0, 1)
            i.instanceCount = 8
            return i
        }()
        
        replicatorLayer?.addSublayer(rayLayer!)
        
        layer.addSublayer(circleLayer!)
        layer.addSublayer(replicatorLayer!)
    }
    
    private func configureConstraints() {
        snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
    }

}
