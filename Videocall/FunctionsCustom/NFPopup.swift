//
//  NFPopup.swift
//  NFClient
//
//  Created by NhatNguyen on 5/22/20.
//  Copyright © 2020 PeerClient. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class NFPopup {
    
    var user_id = ""
    var access_token = ""
    var token = "JWT"
    var tokenCallPeer = ""
    let screenLayout: String = "CALL_VIDEO_SUCCESS"
    var startCalling: Bool = true
    var setupPeerServerFail: Bool = false
    var callSDK: Bool = false
    
    @objc public final func iDismiss(completion: @escaping (Bool) -> ())
    {

       if let viewWithTag = appVar.viewPopupConfirmNext.viewWithTag(2013) {
           viewWithTag.removeFromSuperview()
       }
    
       appVar.PopupConfirmNextFrameBg.frame.origin.y = appVar.UIheight
       appVar.PopupConfirmNextFrameBg.isHidden = true
       completion(true)
    }

    //, actionButton: Selector
    func showPopupConfirmNotify(window: UIApplication ,vcc: UIViewController, content: String)
    {
        NFPopup().iDismiss { (status) in }
        
        let _popupAnsewerCall = popupAnsewerCall(frame: CGRect(x: 0, y: 0, width: appVar.UIwidth, height: 294))
        
        if let viewWithTag = appVar.viewPopupConfirmNext.viewWithTag(2013) {
            viewWithTag.removeFromSuperview()
        }

        _popupAnsewerCall.acceptCall.addTarget(vcc, action: #selector(vcc.acceptCall), for: .touchUpInside)
        
        _popupAnsewerCall.denyCall.addTarget(vcc, action:  #selector(vcc.denyCall), for: .touchUpInside)

        _popupAnsewerCall.bgPopup.layer.shadowPath = UIBezierPath(rect: _popupAnsewerCall.bgPopup.bounds).cgPath
        _popupAnsewerCall.bgPopup.layer.shadowRadius = 15
        _popupAnsewerCall.bgPopup.layer.shadowOffset = .zero
        _popupAnsewerCall.bgPopup.layer.shadowOpacity = 0.3
        
        appVar.PopupConfirmNextFrameBg.isHidden = false
        appVar.PopupConfirmNextFrameBg.layer.frame = CGRect(x: 0, y: 0, width: appVar.UIwidth, height: appVar.UIheight)
        appVar.PopupConfirmNextFrameBg.backgroundColor = UIColor.init(hex: 0x000000, alpha: 0.5)

        appVar.viewPopupConfirmNext.frame = CGRect(x: 0, y: (appVar.UIheight - 300) / 2, width: appVar.UIwidth, height: appVar.UIheight)
        _popupAnsewerCall.tag = 2013
        appVar.viewPopupConfirmNext.addSubview(_popupAnsewerCall)
        appVar.PopupConfirmNextFrameBg.addSubview(appVar.viewPopupConfirmNext)
//        appVar.PopupConfirmNextFrameBg.layer.zPosition = 99999
        appVar.PopupConfirmNextFrameBg.frame = window.keyWindow!.bounds
       // bật lại đoạn này
//        let win:UIWindow = window.delegate!.window!!
        getTopMostViewController()!.view.addSubview(appVar.PopupConfirmNextFrameBg)
        
//        vcc.view.addSubview(appVar.PopupConfirmNextFrameBg)
    }
    
    func showProcessingLoading(vcc: UIViewController, content: String)
    {
        NFPopup().iDismiss { (status) in }
        let _ProcessingLoading = ProcessingLoading(frame: CGRect(x: 0, y: 0, width: appVar.UIwidth, height: 250))
        
        if let viewWithTag = appVar.viewPopupConfirmNext.viewWithTag(2012) {
            viewWithTag.removeFromSuperview()
        }
        
        setUpAnimation(uv: _ProcessingLoading.uiviewLoad)
//        _ProcessingLoading.content.text = content
        
        _ProcessingLoading.bgPopup.layer.shadowPath = UIBezierPath(rect: _ProcessingLoading.bgPopup.bounds).cgPath
        _ProcessingLoading.bgPopup.layer.shadowRadius = 15
        _ProcessingLoading.bgPopup.layer.shadowOffset = .zero
        _ProcessingLoading.bgPopup.layer.shadowOpacity = 0.3
        
        appVar.PopupConfirmNextFrameBg.isHidden = false
        appVar.PopupConfirmNextFrameBg.layer.frame = CGRect(x: 0, y: 0, width: appVar.UIwidth, height: appVar.UIheight)
        appVar.PopupConfirmNextFrameBg.backgroundColor = UIColor.init(hex: 0x000000, alpha: 0)

        appVar.viewPopupConfirmNext.frame = CGRect(x: 0, y: (appVar.UIheight - 250) / 2, width: appVar.UIwidth, height: appVar.UIheight)
        
        _ProcessingLoading.tag = 2012
        appVar.viewPopupConfirmNext.addSubview(_ProcessingLoading)
        appVar.PopupConfirmNextFrameBg.addSubview(appVar.viewPopupConfirmNext)
        getTopMostViewController()!.view.addSubview(appVar.PopupConfirmNextFrameBg)
    }
    
    @objc public final func checkUserAnswer()
    {
        _checkUserAnswer()
    }
    
    func _checkUserAnswer()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if appVar.countWaitAnswer > 39 {
                endMusicWait()
                NFPopup().iDismiss { (status) in }
            }
            
            if !appVar.isAnsewerCall && appVar.countWaitAnswer < 40 {
                self._checkUserAnswer()
            }
            appVar.countWaitAnswer = appVar.countWaitAnswer + 1
            if appVar.debug {
                print("Đợi user bấm click lần: \(appVar.countWaitAnswer)")
            }
        }
    }
    
    @objc func startCallVideo(){
        NFPopup().showProcessingLoading(vcc: appVar.LIVESTREAMVC, content: "Vui lòng chờ trong giây lát")
        
//        setupPeerConnectOnApp(retry: false)
    }
    
    private final func setUpAnimation(uv: UIView) {
        let animation = NFAIAnimationSpinnerDots()
        animation.setUpAnimation(uv: uv, color: UIColor.init(hex: 0x02A9E9, alpha: 1))
    }
    
    @objc func startCallVideoLian(){
        print("hahaha- vào day")
    }
    
}

