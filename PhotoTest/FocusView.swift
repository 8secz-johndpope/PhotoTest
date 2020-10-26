//
//  FocusView.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 22.10.2020.
//

import UIKit

class FocusView: UIView {
    
    private var focusLayer: CAShapeLayer?

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
        if focusLayer == nil {
            configureViews()
        }
    }
    
    private func configureViews() {
        let path: UIBezierPath = {
            let i = UIBezierPath(rect: bounds)
            i.lineWidth = 2
            return i
        }()
        
        focusLayer = {
            let i = CAShapeLayer()
            i.path = path.cgPath
            i.strokeColor = UIColor(red: 244/255, green: 222/255, blue: 89/255, alpha: 1).cgColor
            i.fillColor = UIColor.clear.cgColor
            return i
        }()
        
        layer.addSublayer(focusLayer!)
    }
    
    private func configureConstraints() {
        snp.makeConstraints {
            $0.width.height.equalTo(80)
        }
    }
    
}
