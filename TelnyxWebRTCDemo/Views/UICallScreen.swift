//
//  UICallScreen.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import UIKit
import WebRTCSDK

protocol UICallScreenDelegate {
    func onCallButton()
    func onEndCallButton()
    func onMuteUnmuteSwitch(isMuted: Bool)
    func onHoldUnholdSwitch(isOnHold: Bool)
    func onToggleSpeaker(isSpeakerActive: Bool)
}

@IBDesignable
class UICallScreen: UIView {
    
    let kCONTENT_XIB_NAME = "UICallScreen"
    
    private var textFields:[UITextField] = [UITextField]()
    
    var delegate: UICallScreenDelegate?
    var isSpeakerActive: Bool = true
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var destinationNumberOrSip: UITextField!
    @IBOutlet weak var callControlsSection: UIStackView!
    @IBOutlet weak var muteUnmuteLabel: UILabel!
    @IBOutlet weak var muteUnmuteSwitch: UISwitch!
    @IBOutlet weak var holdUnholdSwitch: UISwitch!
    @IBOutlet weak var holdUnholdLabel: UILabel!
    @IBOutlet weak var toggleSpeaker: UIButton!
    
    
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
    
    private func commonInit() {
        contentView = loadViewFromNib()
        contentView.frame = bounds
        
        contentView.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth,
                                        UIView.AutoresizingMask.flexibleHeight]
        
        addSubview(contentView)
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 0
        self.callControlsSection.isHidden = true
        self.toggleSpeaker(self)
        self.destinationNumberOrSip.autocorrectionType = .no
        self.destinationNumberOrSip.returnKeyType = .done
        self.destinationNumberOrSip.delegate = self
    }
    
    private func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    func hideCallButton(hide: Bool) {
        self.callButton.isHidden = hide
    }
    
    func hideEndButton(hide: Bool) {
        self.endButton.isHidden = hide
    }
    
    func updateButtonsState(callState: CallState, incomingCall: Bool) {
        
        DispatchQueue.main.async {
            switch(callState) {
            case .RINGING:
                self.endButton.isHidden = false
                if (!incomingCall) {
                    self.callButton.isHidden = true
                    self.destinationNumberOrSip.isHidden = true
                    self.callControlsSection.isHidden = false
                }
                break
            case .ACTIVE, .HELD, .CONNECTING:
                self.callControlsSection.isHidden = false
                self.endButton.isHidden = false
                self.callButton.isHidden = true
                self.destinationNumberOrSip.isHidden = true
                break
            case .DONE, .NEW:
                self.destinationNumberOrSip.isHidden = false
                self.callButton.isHidden = false
                self.endButton.isHidden = true
                self.callControlsSection.isHidden = true
                break
            }
        }
    }
    
    func resetHoldUnholdState() {
        self.holdUnholdSwitch.setOn(false, animated: false)
        self.holdUnholdLabel.text = "Hold"
    }

    @IBAction func callButtonTapped(_ sender: Any) {
        self.delegate?.onCallButton()
    }
    
    @IBAction func endButtonTapped(_ sender: Any) {
        self.delegate?.onEndCallButton()
    }

    @IBAction func muteUnmuteTapped(_ sender: Any) {
        if (muteUnmuteSwitch.isOn) {
            self.muteUnmuteLabel.text = "Unmute"
        } else {
            self.muteUnmuteLabel.text = "Mute"
        }
        self.delegate?.onMuteUnmuteSwitch(isMuted: muteUnmuteSwitch.isOn)
    }

    @IBAction func holdUnholdTapped(_ sender: Any) {
        if (holdUnholdSwitch.isOn) {
            self.holdUnholdLabel.text = "Unhold"
        } else {
            self.holdUnholdLabel.text = "Hold"
        }
        self.delegate?.onHoldUnholdSwitch(isOnHold: holdUnholdSwitch.isOn)
    }

    @IBAction func toggleSpeaker(_ sender: Any) {
        self.isSpeakerActive = !self.isSpeakerActive
        if (isSpeakerActive) {
            let image = UIImage(systemName: "speaker")
            self.toggleSpeaker.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "speaker.slash")
            self.toggleSpeaker.setImage(image, for: .normal)
        }
        self.delegate?.onToggleSpeaker(isSpeakerActive: self.isSpeakerActive)
    }

}

// MARK: - UITextFieldDelegate
extension UICallScreen : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //Dismiss keyboard when done.
        textField.resignFirstResponder()
    }
}
