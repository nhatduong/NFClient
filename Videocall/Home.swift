//
//  Main.swift
//  videocall
//
//  Created by NhatNguyen on 1/20/20.
//  Copyright © 2020 NhatNguyen. All rights reserved.
//

import UIKit
import NFClient
import AVFoundation

class Home: UIViewController {
    
    @IBOutlet weak var call_id: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    

    
    @IBAction func callingtoBank(_ sender: Any) {
    
        
        
        if let urlString = Bundle.main.path(forResource: "VideoCallNFKit", ofType: "framework", inDirectory: "Frameworks") {
            let bundle = (Bundle(url: NSURL(fileURLWithPath: urlString) as URL))
            let sb = UIStoryboard(name: "Home", bundle: bundle)
            let vc = sb.instantiateViewController(withIdentifier: "VideoCallID")
        

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: false, completion: nil)
            }
        }
        
    }
    
    


}
