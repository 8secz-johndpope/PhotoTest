//
//  ViewController.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 07.10.2020.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var testButton: UIButton!
    
    lazy var imagePicker: ImagePicker = {
        let i = ImagePicker(presentationController: self, delegate: self)
        return i
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gr = RecordGestureRecognizer(target: self, action: #selector(timeoutDetected), timeout: 5)
        testButton.addGestureRecognizer(gr)
    }
    
    @objc func timeoutDetected() {
        print("GESTURE: TIMEOUT DETECTED")
    }
    
    @IBAction func choseFromGalery(_ sender: Any) {
//        let vc = GalleryViewController()
        navigationController?.present(imagePicker.pickerController(for: .photoLibrary, mode: .photo)!, animated: true)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        guard let vc = imagePicker.pickerController(for: .camera, mode: .photo) else {
            print("No PickerViewController")
            return
        }
        
        present(vc, animated: true)
    }
    
    @IBAction func openCamera(_ sender: Any) {
        let vc = CameraViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func takeVideo(_ sender: Any) {
        guard let vc = imagePicker.pickerController(for: .camera, mode: .video) else {
            print("No PickerViewController")
            return
        }
        
        present(vc, animated: true)
    }
}

extension ViewController: ImagePickerDelegate {
    
    func didSelect(image: UIImage?) -> UIViewController? {
//        imageView.image = image
        return nil
    }
    
}
