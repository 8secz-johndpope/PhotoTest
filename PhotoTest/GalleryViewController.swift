//
//  GalleryViewController.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 14.10.2020.
//

import UIKit
import Photos

class GalleryViewController: UIViewController {
    
    weak var collectionView: UICollectionView!
    
    var assets: [PHAsset] = []
    var processingRequests: [IndexPath: PHImageRequestID] = [:]
    
    var size: CGSize {
        let side = (collectionView.frame.width - 4) / 3
        return CGSize(width: side, height: side)
    }
    
    var requestOptions: PHImageRequestOptions = {
        let i = PHImageRequestOptions()
        i.resizeMode = .exact
        i.deliveryMode = .highQualityFormat
        return i
    }()
    
    lazy var imageManager: PHCachingImageManager = {
        let i = PHCachingImageManager()
        return i
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            reloadAssets()
        } else {
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
                if status == .authorized {
                self.reloadAssets()
                } else {
                    print("WARNING: NEED ACCESS")
                }
            })
        }
    }
    
    func fetch(_ completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            let mediaResult = PHAsset.fetchAssets(with: options)
            mediaResult.enumerateObjects { (asset, inde, stop) in
                self.assets.append(asset)
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
        
    private func reloadAssets() {
        assets.removeAll()
        
        fetch {
            self.imageManager.startCachingImages(for: self.assets, targetSize: self.size, contentMode: .aspectFill, options: self.requestOptions)
            self.collectionView.reloadData()
        }
    }
    
    func setup() {
        title = "Фото"
        
        view.backgroundColor = .white
        
        let collectionView: UICollectionView = {
            let i = UICollectionView(frame: view.frame, collectionViewLayout: UICollectionViewFlowLayout())
            i.register(GalleryCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
//            i.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            i.backgroundColor = .white
            return i
        }()
        self.collectionView = collectionView
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        view.addSubview(self.collectionView)
        
        self.collectionView.translatesAutoresizingMaskIntoConstraints = true
        self.collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

extension GalleryViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GalleryCollectionViewCell
        let asset = assets[indexPath.row]
        
        let request = imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: requestOptions,
            resultHandler: { (image, options) in
                cell.imageView.image = image
            })
        
        cell.requestID = request
        cell.cancelHandler = { [unowned self] in
            guard let request = $0 else { return }
            self.imageManager.cancelImageRequest(request)
        }
        
        if asset.mediaType == .video {
            cell.durationLabel.text = "\(asset.duration) сек"
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
}
