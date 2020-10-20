//
//  CameraView.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 19.10.2020.
//

import UIKit
import SnapKit
import BetterSegmentedControl

final class CameraView: UIView {

    var previewView: PreviewView!
    var activityIndicator: UIActivityIndicatorView!
    var recordButton: UIButton!
    var photoVideoControl: BetterSegmentedControl!
    var changeCameraButton: UIButton!
    var flashButton: UIButton!
    var videoProgressView: UIProgressView!
    var timerLabel: UILabel!

    private var controlsView: UIView!
    private var stackView: UIStackView!
    private var controlsStackView: UIStackView!
    private var photoVideoControlWrapper: UIView!
    private var videoProgressViewWrapper: UIView!
    private var timerLabelWrapper: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViews() {
        backgroundColor = .white
        
        previewView = {
            let i = PreviewView()
            i.videoPreviewLayer.videoGravity = .resizeAspectFill
            return i
        }()
        
        activityIndicator = {
            let i = UIActivityIndicatorView(style: .white)
            i.hidesWhenStopped = true
            return i
        }()
        
        recordButton = {
            let i = UIButton()
            i.setImage(UIImage(named: "record"), for: .normal)
            i.setImage(UIImage(named: "stopRecord"), for: .selected)
            return i
        }()
        
        photoVideoControl = {
            let i = BetterSegmentedControl(
                frame: .zero,
                segments: LabelSegment.segments(withTitles: ["Photo", "Video"], normalTextColor: .gray, selectedTextColor: .gray),
                index: 0,
                options: [
                    .backgroundColor(.white),
                    .indicatorViewBackgroundColor(.lightGray),
                    .cornerRadius(10),
                    .panningDisabled(true)
                ])
            return i
        }()
        
        photoVideoControlWrapper = {
            let i = UIView()
            return i
        }()
        
        changeCameraButton = {
            let i = UIButton()
            i.setImage(UIImage(named: "frame"), for: .normal)
            return i
        }()
        
        flashButton = {
            let i = UIButton()
            i.setImage(UIImage(named: "flash"), for: .normal)
            return i
        }()
        
        videoProgressView = {
            let i = UIProgressView()
            i.progressTintColor = .blue
            i.trackTintColor = .lightGray
            i.isHidden = true
            return i
        }()
        
        videoProgressViewWrapper = {
            let i = UIView()
            return i
        }()
        
        timerLabel = {
            let i = UILabel()
            i.text = "00:00"
            i.isHidden = true
            i.textAlignment = .center
            return i
        }()
        
        timerLabelWrapper = {
            let i = UIView()
            return i
        }()
        
        controlsView = {
            let i = UIView()
            i.backgroundColor = .white
            return i
        }()
        
        stackView = {
            let i = UIStackView()
            i.axis = .vertical
            return i
        }()
        
        controlsStackView = {
            let i = UIStackView()
            i.axis = .vertical
            return i
        }()
        
        addSubview(stackView)
        
        stackView.addArrangedSubview(previewView)
        stackView.addArrangedSubview(controlsView)
        
        previewView.addSubview(changeCameraButton)
        previewView.addSubview(flashButton)
        previewView.addSubview(activityIndicator)
        
        controlsView.addSubview(controlsStackView)
        
        controlsStackView.addArrangedSubview(videoProgressViewWrapper)
        controlsStackView.addArrangedSubview(photoVideoControlWrapper)
        controlsStackView.addArrangedSubview(timerLabelWrapper)
        controlsStackView.addArrangedSubview(recordButton)
        
        photoVideoControlWrapper.addSubview(photoVideoControl)
        videoProgressViewWrapper.addSubview(videoProgressView)
        timerLabelWrapper.addSubview(timerLabel)
    }
    
    private func configureConstraints() {
        
        controlsStackView.setCustomSpacing(10, after: videoProgressViewWrapper)
        controlsStackView.setCustomSpacing(22, after: photoVideoControlWrapper)
        controlsStackView.setCustomSpacing(16, after: timerLabelWrapper)
        
        stackView.snp.makeConstraints {
            $0.edges.equalTo(safeAreaLayoutGuide)
        }
        
        previewView.snp.makeConstraints {
            $0.height.equalToSuperview().multipliedBy(0.65)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        changeCameraButton.snp.makeConstraints {
            $0.leading.equalTo(17)
            $0.bottom.equalTo(-25)
        }
        
        flashButton.snp.makeConstraints {
            $0.trailing.equalTo(-17)
            $0.bottom.equalTo(-25)
        }
        
        controlsStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(11)
            $0.leading.equalToSuperview().offset(11)
            $0.trailing.equalToSuperview().offset(-11)
            $0.bottom.lessThanOrEqualTo(controlsView).offset(-11)
        }
        
        photoVideoControl.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40))
            $0.height.equalTo(30)
        }
        
        recordButton.snp.makeConstraints {
            $0.height.width.equalTo(60)
        }
        
        videoProgressView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(2)
        }
        
        timerLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
    }
    
}
