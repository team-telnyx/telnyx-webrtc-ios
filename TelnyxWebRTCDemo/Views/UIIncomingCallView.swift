//
//  UIIncomingCallView.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 19/01/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation
import UIKit
import TelnyxRTC

protocol UIIncomingCallViewDelegate: AnyObject {
    func onAnswerButton()
    func onRejectButton()
}

@IBDesignable
class UIIncomingCallView: UIView {

    let kCONTENT_XIB_NAME = "UIIncomingCallView"

    private var textFields:[UITextField] = [UITextField]()

    weak var delegate: UIIncomingCallViewDelegate?
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var answerButton: UIButton!

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
    }

    private func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView

        return view
    }

    func updateButtonsState(callState: CallState, incomingCall: Bool) {

        if (callState == .RINGING) {
            if (incomingCall) {
                DispatchQueue.main.async {
                    self.answerButton.setTitle("Answer", for: .normal)
                    self.endButton.setTitle("Reject", for: .normal)
                }
            }
        }
    }
    
    @IBAction func answerButtonTapped(_ sender: Any) {
        self.delegate?.onAnswerButton()
    }
    
    @IBAction func endButtonTapped(_ sender: Any) {
        self.delegate?.onRejectButton()
    }
}
