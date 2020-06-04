//
//  Function.swift
//  VideoCallNFKit
//
//  Created by NhatNguyen on 2/19/20.
//  Copyright © 2020 NhatNguyen. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import AVFoundation

func encryptAESString(str: String, key: String, iv: String) -> String
{
    let aes = AES(key: key, iv: iv)
    let encrypted = aes?.encrypt(string: str)
    return (encrypted?.toBase64())!
}

func decryptAESString(str: Data, key: String, iv: String) -> String
{
    let aes = AES(key: key, iv: iv)
    let decrypted = aes?.decrypt(data: str)
    return (decrypted)!
}

func encryptAES(from object: Any, key: String, iv: String) -> String
{
    let dataEncode = convertObjectToJson(from: object as Any)
    let aes = AES(key: key, iv: iv)
    let encrypted = aes?.encrypt(string: dataEncode!)
    return (encrypted?.toBase64())!
}

func convertObjectToJson(from object:Any) -> String? {
    guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
        return nil
    }
    return String(data: data, encoding: String.Encoding.utf8)
}

func checkNetworkShowBottom(vcc: UIViewController, completion: @escaping (Bool) -> Void)
{
//    print("Vao laij")
    if let viewWithTag = vcc.view.viewWithTag(1010) {
        viewWithTag.removeFromSuperview()
    }
    testSpeed { (speed) in
        if !speed {
//            print("Vao day1")
            let bgNetwork: UIView = UIView()
            bgNetwork.backgroundColor = UIColor.init(hex: 0xd1383d, alpha: 1)
            bgNetwork.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height - 44, width: UIScreen.main.bounds.size.width, height: 44)
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
            label.textAlignment = NSTextAlignment.center
            label.text = "Không có kết nối internet"
            label.textColor = .white
            bgNetwork.addSubview(label)
            bgNetwork.tag = 1010
            vcc.view.addSubview(bgNetwork)
            completion(false)
        }else{
            completion(true)
        }
    }
}

func testSpeed(completion: @escaping (Bool) -> Void)  {

    APIVideoCallservice.getpeerServerInfo.get(parameters: "", headers: [:], success: { (Data) in
        completion(true)
    }) { (Error) in
        completion(false)
    }
}

func getTokenOauth(userID: String, token_access: String, completion: @escaping (String) -> Void)
{
//    print("userID\(userID)token\(token)")
    let sign = "\(token_access)\(userID)"
    let sign_md5 = sign.md5()
    let param = "user_id=\(userID)&sign=\(sign_md5)"
    print("\(token_access)paramparamparam\(param)")
    APIVideoCallservice.getOauthToken.get(parameters: param, headers: [:],success: { data in
                            
    do {
        let root = try JSON(data: data)
        if appVar.debug {
            print("getTokenOauth: \(root)")
        }
//
        if root["status"].intValue == 200 {
            completion(root["data"]["token"].stringValue)
        }else{
            completion("NOTTOKEN")
        }
        
    }catch _ as NSError{
        completion("NOTTOKEN")
    }
    }) { (error) in
        completion("NOTTOKEN")
    }
}


func peerServerInfo(apiKey: String, apiSecret: String, token: String, completion: @escaping (JSON) -> Void, error: @escaping () -> Void)
{
    let param = "apiKey=\(apiKey)&apiSecret=\(apiSecret)"
    
    APIVideoCallservice.getpeerServerInfo.get(parameters: param, headers: [
        "Authorization": "Bearer \(token)"
    ], success: { data in
        
    do {
        let root = try JSON(data: data)
        if appVar.debug {
            print("peerServerInfo: \(root)")
        }
        if root["status"].intValue == 200 {
            completion(root)
        }else{
            completion([])
        }
        
    }catch _ as NSError{
        error()
    }
    }) { (_) in
        error()
    }
}

func peerServerIce(apiKey: String, apiSecret: String, completion: @escaping (JSON) -> Void)
{
    let param = "apiKey=\(apiKey)&apiSecret=\(apiSecret)"
    APIVideoCallservice.getpeerServerIce.get(parameters: param, headers: [:], success: { data in
                            
    do {
        let root = try JSON(data: data)
        
        if root["status"].intValue == 200 {
            completion(root)
        }else{
            completion([])
        }
        
    }catch _ as NSError{
        completion([])
    }
    }) { (error) in
        completion([])
    }
}

func countTimeCall(label: UILabel, _seconds: Int, _minute: Int)
{
    var seconds = _seconds
    var minute = _minute
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        seconds = seconds + 1;
        if(seconds > 59)
        {
            seconds = 0;
            minute = minute + 1;
        }
        let _minute = (minute > 9) ? "\(minute)" : "0\(minute)"
        let _seconds = (seconds > 9) ? "\(seconds)" : "0\(seconds)"
        label.text = "\(_minute):\(_seconds)"
        if !appVar.stopCounterTimeCall {
            countTimeCall(label: label, _seconds: seconds, _minute: minute)
        }
    }
}

func showConfirmEndCall(vcc: UIViewController,completion: @escaping (Bool) -> Void)
{
    let dialogMessage = UIAlertController(title: "Xác nhận", message: "Bạn có chắc chắn muốn kết thúc cuộc gọi", preferredStyle: .alert)
    
    // Create OK button with action handler
    let ok = UIAlertAction(title: "Kết thúc", style: .default, handler: { (action) -> Void in
         completion(true)
    })
    
    // Create Cancel button with action handlder
    let cancel = UIAlertAction(title: "Hủy bỏ", style: .cancel) { (action) -> Void in
        completion(false)
    }
    
    //Add OK and Cancel button to dialog message
    dialogMessage.addAction(ok)
    dialogMessage.addAction(cancel)
    
    // Present dialog message to user
    vcc.present(dialogMessage, animated: true, completion: nil)
}

func playMusic()
{
        DispatchQueue.global(qos: .utility).async {
            
            
//            print("Configuration.wait_audio\(Configuration.wait_audio)")
            endMusicWait()
            
            let session = AVAudioSession.sharedInstance()
            var _: Error?
            try? session.setCategory(AVAudioSession.Category.playback)
            try? session.setMode(AVAudioSession.Mode.spokenAudio)
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try? session.setActive(true, options: .notifyOthersOnDeactivation)
            
            let playerItem = AVPlayerItem( url:NSURL( string: Configuration.wait_audio )! as URL )
            appVar.playerAudio.volume = 1
            appVar.playerAudio = AVPlayer(playerItem: playerItem)
            appVar.playerAudio.play()
        }
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: appVar.playerAudio.currentItem, queue: .main) { _ in
            //[weak self]
//            print("play lại nhạc")
            appVar.loopWaithMusicNumber = appVar.loopWaithMusicNumber + 1
            appVar.playerAudio.seek(to: CMTime.zero)
            appVar.playerAudio.play()
        }
}

func endMusicWait()
{
    print("stop nhạc")
    let playerItem = AVPlayerItem( url:NSURL( string: "" )! as URL )
    appVar.playerAudio = AVPlayer(playerItem: playerItem)
    appVar.playerAudio.volume = 0
    appVar.playerAudio.play()
}

func setSpeakerStates(enabled: Bool)
{
    let session = AVAudioSession.sharedInstance()
    var _: Error?
    try? session.setCategory(AVAudioSession.Category.playback)
    try? session.setMode(AVAudioSession.Mode.spokenAudio)
    
    if enabled {
       try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
    } else {
       try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
    }
    
    try? session.setActive(true, options: .notifyOthersOnDeactivation)
    
//    let session = AVAudioSession.sharedInstance()
//    var _: Error?
//    try? session.setCategory(AVAudioSession.Category.playAndRecord)
//    try? session.setMode(AVAudioSession.Mode.voiceChat)
//    if enabled {
//        try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
//    } else {
//       try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
//    }
//    try? session.setActive(true, options: .notifyOthersOnDeactivation)
}

func getTopMostViewController() -> UIViewController? {
    var topMostViewController = UIApplication.shared.keyWindow?.rootViewController

    while let presentedViewController = topMostViewController?.presentedViewController {
        topMostViewController = presentedViewController
    }

    return topMostViewController
}


extension UIColor {
    
    convenience init(hex: Int, alpha: CGFloat) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: alpha)
    }
    
}

extension Data {
    func toBase64() -> String {
        return self.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
}

extension String {

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func decodeBase64() -> Data
    {
        return Data(base64Encoded: self)!
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}
