//
//  YSPhoto.swift
//  yourservice-ios
//
//  Created by Игорь Сорокин on 26.10.2020.
//  Copyright © 2020 spider. All rights reserved.
//

import UIKit

class YSPhoto: YSMedia {
    let image: CIImage
    let bounds: CGSize
    let date: Date
    
    init(image: CIImage, bounds: CGSize, date: Date) {
        self.image = image
        self.bounds = bounds
        self.date = date
    }
}
