//
//  ShortTapGestureRecognizer.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 14.10.2020.
//

import UIKit.UIGestureRecognizerSubclass

class DelayTapGestureRecognizer: UITapGestureRecognizer {
    
    private let tapDelay: Double
    
    init(target: Any?, action: Selector?, tapDelay: Double = 0.3) {
        self.tapDelay = tapDelay
        super.init(target: target, action: action)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + tapDelay) {
            if self.state != .ended {
                self.state = .failed
            }
        }
    }
    
}
