//
//  ImagePicker.swift
//  madyar
//
//  Created by Alexey Ostroverkhov on 16/01/2020.
//  Copyright © 2020 madyar. All rights reserved.
//

import UIKit

public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage?) -> UIViewController?
}

open class ImagePicker: NSObject {

    private lazy var pickerController = UIImagePickerController()
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?

    init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        super.init()

        self.presentationController = presentationController
        self.delegate = delegate

        pickerController.allowsEditing = true
        pickerController.delegate = self
    }

    
    func pickerController(for type: UIImagePickerController.SourceType, mode: UIImagePickerController.CameraCaptureMode?) -> UIViewController? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        pickerController.sourceType = type
        
        switch type {
        case .photoLibrary, .savedPhotosAlbum:
            
            pickerController.mediaTypes = ["public.image", "public.movie"]
            
        case .camera:
            pickerController.mediaTypes = [(mode == .photo) ? "public.image" : "public.movie"]
            pickerController.cameraDevice = .rear
            pickerController.cameraCaptureMode = mode ?? .photo
            pickerController.cameraFlashMode = .auto
//            pickerController.cameraViewTransform = CGAffineTransform(rotationAngle: 45)
            pickerController.showsCameraControls = true
            
        @unknown default:
            fatalError()
        }
        
        return pickerController
    }
    

    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        

        if let vc = self.delegate?.didSelect(image: image), controller.sourceType == .camera {
            controller.dismiss(animated: false) {
                self.presentationController?.present(
                    vc,
                    animated: false,
                    completion: nil
                )
            }
        } else if let vc = self.delegate?.didSelect(image: image) {
            controller.pushViewController(vc, animated: true)
        } else {
            controller.dismiss(animated: true)
        }
        
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        self.pickerController(picker, didSelect: image)
    }
}

extension ImagePicker: UINavigationControllerDelegate {

}
