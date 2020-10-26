//
//  ControlsView.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 22.10.2020.
//

import UIKit

class ControlsView: UIView {

    private(set) var focusView: FocusView!
    private(set) var exposureView: ExposureView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
        configureConstraints()
    }
    
    func setExposureY(factor: CGFloat) {
        
    }
    
    private func configureViews() {
        alpha = 0.9
        
        focusView = {
            let i = FocusView()
            return i
        }()
        
        exposureView = {
            let i = ExposureView()
            return i
        }()
        
        addSubview(focusView)
        addSubview(exposureView)
    }
    
    private func configureConstraints() {
        focusView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().offset(-8)
        }
        
        exposureView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalTo(focusView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
    
}
