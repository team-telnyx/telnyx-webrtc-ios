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
