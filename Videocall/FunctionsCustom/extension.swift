//
//  extension.swift
//  NFClient
//
//  Created by NhatNguyen on 6/1/20.
//  Copyright © 2020 PeerClient. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

extension UIViewController {
    
    @objc func denyCall()
    {
        //appVar.playerAudio.pause()
        endMusicWait()
        appVar.countWaitAnswer = 41
        print("Push vào đây ")
        appVar.socket.emit("user_deny_call", ["user_id": appVar.adminIDCaller, "sign": encryptAESString(str: appVar.adminIDCaller, key: appVar.key, iv: appVar.iv)]);
        NFPopup().iDismiss { (status) in }
    }
    
    @objc func acceptCall(){
        if let urlString = Bundle.main.path(forResource: "NFClient", ofType: "framework", inDirectory: "Frameworks") {
            
            appVar.isAnsewerCall = true
            appVar.socket.emit("user_receive_call", ["user_id": appVar.adminIDCaller, "sign": encryptAESString(str: appVar.adminIDCaller, key: appVar.key, iv: appVar.iv)]);
            
            endMusicWait()
            //appVar.playerAudio.pause()
            
            NFPopup().iDismiss { (status) in
                NFPopup().showProcessingLoading(vcc: appVar.LIVESTREAMVC, content: "Xin đợi")
            }
            
            print("GET LINK CALL")
            
            let bundle = (Bundle(url: NSURL(fileURLWithPath: urlString) as URL))
            let sb = UIStoryboard(name: "Home", bundle: bundle)
            let vc = sb.instantiateViewController(withIdentifier: "VideoCallID")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                vc.modalPresentationStyle = .fullScreen
                
                DispatchQueue.main.async {
                    getTopMostViewController()?.present(vc, animated: false, completion: nil)
                }
                
            }
        }
    }
}


