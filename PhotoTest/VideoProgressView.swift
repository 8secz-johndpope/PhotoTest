//
//  VideoProgressView.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 19.10.2020.
//

import UIKit

class VideoProgressView: UIProgressView {

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: frame.width, height: 2)
    }

}
