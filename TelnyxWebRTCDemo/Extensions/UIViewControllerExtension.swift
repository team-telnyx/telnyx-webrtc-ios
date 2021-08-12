//
//  UIViewControllerExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 02/03/2021.
//

import UIKit

extension UIViewController {
    var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
}


// Keyboard handling
extension UIViewController {

    func showLoadingView() {
        let loadingView = LoadingView(frame: self.view.frame)
        self.view.addSubview(loadingView)
    }

    func removeLoadingView() {
        if let loadingView = self.view.subviews.first(where: { $0 is LoadingView }) {
            loadingView.removeFromSuperview()
        }
    }

    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
