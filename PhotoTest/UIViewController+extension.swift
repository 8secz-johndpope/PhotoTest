//
//  UIViewController+extension.swift
//  PhotoTest
//
//  Created by Игорь Сорокин on 12.10.2020.
//

import UIKit

extension UIViewController {
    func showTurnOnCameraAlert() {
        let settings = UIAlertAction(title: "Настройки", style: .default, handler: { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        })
        
        let cancel = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        
        let alert = UIAlertController(title: "Включите камеру в настройках", message: nil, preferredStyle: .alert)
        alert.addAction(settings)
        alert.addAction(cancel)
        
        present(alert, animated: true)
    }
    
    func showInfoAlert(_ info: String?) {
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        let alert = UIAlertController(title: nil, message: info, preferredStyle: .alert)
        alert.addAction(ok)
        
        present(alert, animated: true)
    }
}
