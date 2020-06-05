//
//  popupAnsewerCall.swift
//  NFClient
//
//  Created by NhatNguyen on 5/22/20.
//  Copyright © 2020 PeerClient. All rights reserved.
//

import UIKit

class popupAnsewerCall: UIView {

    @IBOutlet var view: UIView!
    @IBOutlet weak var bgPopup: UIView!
    @IBOutlet weak var avatarCaller: UIImageView!
    @IBOutlet weak var acceptCall: UIButton!
    @IBOutlet weak var denyCall: UIButton!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bgPopup.layer.cornerRadius = 15
        bgPopup.layer.masksToBounds = true
        avatarCaller.layer.cornerRadius = avatarCaller.layer.frame.width / 2
        avatarCaller.layer.masksToBounds = true
        acceptCall.layer.cornerRadius = 22
        acceptCall.layer.masksToBounds = true
        denyCall.layer.cornerRadius = 22
        denyCall.layer.masksToBounds = true
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "popupAnsewerCall", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        return view
    }

}
