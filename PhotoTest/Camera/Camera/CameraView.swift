//
//  CameraView.swift
//  yourservice-ios
//
//  Created by Igor Sorokin on 26/10/2020.
//

import UIKit

final class CameraView: UIView {
    
    var previewView: PreviewView!
    var videoButton: UIButton!
    var photoButton: UIButton!
    var secordsLabel: UILabel!
    var progressView: UIProgressView!
    var captureButton: CaptureButton!
    
    private var bottomView: UIView!
    
    init(options: CameraOptions) {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        prepareFor(options: options)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        backgroundColor = .black
        
        previewView = {
            let i = PreviewView()
            i.videoPreviewLayer.videoGravity = .resizeAspectFill
            i.backgroundColor = .black
            return i
        }()
        
        bottomView = {
            let i = UIView()
            i.backgroundColor = .black
            return i
        }()
        
        secordsLabel = {
            let i = UILabel()
            i.textColor = .white
            i.font = .systemFont(ofSize: 14, weight: .medium)
            i.text = "0:00"
            i.isHidden = true
            return i
        }()
        
        progressView = {
            let i = UIProgressView()
            i.progressTintColor = .primary
            i.trackTintColor = UIColor.Text.quaternary
            i.isHidden = true
            return i
        }()
        
        videoButton = {
            let i = UIButton()
            i.setImage(Asset.videoIcon.image, for: .normal)
            i.setImage(Asset.videoIconSelected.image, for: .selected)
            return i
        }()
        
        photoButton = {
            let i = UIButton()
            i.setImage(Asset.photoIcon.image, for: .normal)
            i.setImage(Asset.photoIconSelected.image, for: .selected)
            i.isSelected = true
            return i
        }()
        
        captureButton = {
            let i = CaptureButton()
            i.prepareForConfiguration(.photo)
            return i
        }()

        addSubview(previewView)
        addSubview(captureButton)
        addSubview(bottomView)
        
        bottomView.addSubview(photoButton)
        bottomView.addSubview(videoButton)
        bottomView.addSubview(progressView)
        bottomView.addSubview(secordsLabel)
    }
    
    private func setupConstraints() {
        previewView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            $0.bottom.equalTo(bottomView.snp.top)
        }
        
        bottomView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        captureButton.snp.makeConstraints {
            $0.width.height.equalTo(67)
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(bottomView.snp.top).offset(-8)
        }
        
        photoButton.snp.makeConstraints {
            $0.top.equalTo(20)
            $0.leading.equalTo(20)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-20)
        }
        
        videoButton.snp.makeConstraints {
            $0.top.equalTo(20)
            $0.trailing.equalTo(-20)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-20)
        }
        
        progressView.snp.makeConstraints {
            $0.leading.equalTo(photoButton.snp.trailing).offset(22)
            $0.trailing.equalTo(videoButton.snp.leading).offset(-22)
            $0.centerY.equalTo(photoButton)
        }
        
        secordsLabel.snp.makeConstraints {
            $0.top.equalTo(8)
            $0.centerX.equalToSuperview()
        }
        
    }
    
    private func prepareFor(options: CameraOptions) {
        if options.isPhotoOnly {
            videoButton.isHidden = true
        }
        
        if options.isVideoOnly {
            photoButton.isHidden = true
        }
    }

}
