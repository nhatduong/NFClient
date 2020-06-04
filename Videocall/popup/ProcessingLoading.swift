//
//  ProcessingLoading.swift
//  NFClient
//
//  Created by NhatNguyen on 5/26/20.
//  Copyright © 2020 PeerClient. All rights reserved.
//

import Foundation
import UIKit

class ProcessingLoading: UIView {

    @IBOutlet weak var image_loading: UIImageView!
    @IBOutlet weak var content: UILabel!
    @IBOutlet weak var bgPopup: UIView!
    @IBOutlet var view: UIView!
    @IBOutlet weak var uiviewLoad: UIView!
    
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
        
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "ProcessingLoading", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        return view
    }
    
}
