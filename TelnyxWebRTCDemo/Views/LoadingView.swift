//
//  LoadingView.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 09/08/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.

import UIKit

class LoadingView: UIView {

    var background: UIVisualEffectView?

    override init(frame: CGRect) {
        let blurEffect = UIBlurEffect(style: .dark)
        let background = UIVisualEffectView(effect: blurEffect)
        background.frame = frame
        background.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.background = background
        super.init(frame: frame)
        addSubview(background)
        addLoader()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addLoader() {
        guard let background = background else { return }
        let activityIndicator = UIActivityIndicatorView(style: .white)
        background.contentView.addSubview(activityIndicator)
        activityIndicator.center = background.contentView.center
        activityIndicator.startAnimating()
    }
}
