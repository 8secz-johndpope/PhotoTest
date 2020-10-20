//
//  GalleryCollectionViewCell.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 14.10.2020.
//

import UIKit
import Photos

class GalleryCollectionViewCell: UICollectionViewCell {
    
    weak var imageView: UIImageView!
    weak var durationLabel: UILabel!
    
    var requestID: PHImageRequestID?
    var cancelHandler: ((PHImageRequestID?) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        cancelHandler?(requestID)
        durationLabel.text = nil
    }
    
    func setup() {
        let imageView: UIImageView = {
            let i = UIImageView(frame: contentView.frame)
            return i
        }()
        
        self.imageView = imageView
        contentView.addSubview(self.imageView)
        
        self.imageView.translatesAutoresizingMaskIntoConstraints = true
        self.imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        
        let label: UILabel = {
            let i = UILabel(frame: contentView.frame)
            return i
        }()
        
        self.durationLabel = label
        contentView.addSubview(self.durationLabel)
        
        self.durationLabel.translatesAutoresizingMaskIntoConstraints = true
        self.durationLabel.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
    }
    
}
