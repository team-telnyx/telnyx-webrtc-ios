//
//  UISettingsView.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import UIKit

@IBDesignable
class UISettingsView: UIView {
    
    let kCONTENT_XIB_NAME = "UISettingsView"
    
    private var textFields:[UITextField] = [UITextField]()
    private var activeField: UITextField?

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var sipUsernameLabel: UITextField!
    @IBOutlet weak var callerIdNumberLabel: UITextField!
    @IBOutlet weak var callerIdNameLabel: UITextField!
    @IBOutlet weak var passwordUserNameLabel: UITextField!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func prepareForInterfaceBuilder() {
        commonInit()
    }
    
    deinit {
        self.unsubscribeKeyboardEvents()
    }
    
    private func commonInit() {
        contentView = loadViewFromNib()
        contentView.frame = bounds
        
        contentView.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth,
                                        UIView.AutoresizingMask.flexibleHeight]
        
        addSubview(contentView)
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 0
        
        self.setupTextFields()
        self.subscribeKeyboardEvents()
        
    }
    
    private func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    private func setupTextFields() {
        
        self.textFields.append(self.sipUsernameLabel)
        self.textFields.append(self.passwordUserNameLabel)
        self.textFields.append(self.callerIdNameLabel)
        self.textFields.append(self.callerIdNumberLabel)
        
        for i in 0...(self.textFields.count - 1) {
            let textField = self.textFields[i]
            textField.delegate = self
            textField.tag = i
            textField.returnKeyType = .done
            textField.autocorrectionType = .no
        }
    }
}


extension UISettingsView : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField){
        self.activeField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField){
        self.activeField = nil
    }
}

// MARK: - Keyboard handling
extension UISettingsView {

    /**
     This function executed when the keyboard will be displayed
     */
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.superview?.frame.origin.y == 0 {
                if let field = activeField {
                    let frame = field.convert(field.bounds, to: nil)
                    let screenSize = UIScreen.main.bounds
                    let yFromBottom: CGFloat = screenSize.height - frame.origin.y - field.frame.height
                    if (yFromBottom < keyboardSize.height) {
                        let offset = keyboardSize.height - yFromBottom
                        self.superview?.frame.origin.y -= offset
                   }
                }
            }
        }
    }

    /**
     This function is executed when the keyboard is being hidden
     */
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.superview?.frame.origin.y != 0 {
            self.superview?.frame.origin.y = 0
        }
    }

    /**
     Listen to keyboard changes
     */
    private func subscribeKeyboardEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /**
     Stop listening keyboard events
     */
    private func unsubscribeKeyboardEvents() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

