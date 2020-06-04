//
//  VideoCallNFKit.swift
//  VideoCallNFKit
//
//  Created by NhatNguyen on 2/13/20.
//  Copyright © 2020 NhatNguyen. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

//public struct appVar {
//
//    static var apiServer = ""
//    static var sockerServer = ""
//    static var apiKey = ""
//    static var apiSecret = ""
//    static var userID = ""
//    static var token = ""
//    static var tokenCallPeer = ""
//    static var isScreenCalling: Bool = true
//    static var startCalling: Bool = true
//    static var onDoneEventEndCall: ((Bool) -> Void)?
//    static var stopCounterTimeCall: Bool = true
//}
//
//
//
//public class VideoCallNFKit: UIViewController {
//
//
//    required init?(coder: NSCoder) {
//
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    public class func setupCallVideoNF(apiServer: String, socketServer: String, apiKey: String, apiSecret: String, userID: String, token: String, onDoneEventEndCall : ((Bool) -> Void)?, completion: @escaping (String) -> Void) {
//
//        appVar.apiServer = apiServer
//        appVar.sockerServer = socketServer
//        appVar.apiKey = apiKey
//        appVar.apiSecret = apiSecret
//        appVar.userID = userID
//        appVar.token = token
//
//        appVar.onDoneEventEndCall = onDoneEventEndCall
//
//        getTokenOauth(userID: userID, token: token) { (tokenOauth) in
//
//            if tokenOauth == "NOTTOKEN" {
//                completion(tokenOauth)
//            }else{
//                peerServerInfo(apiKey: appVar.apiKey, apiSecret: appVar.apiSecret, completion: { (_JSON) in
//                    if _JSON["status"].intValue == 200 {
//
//                        Configuration.peerId = _JSON["data"]["peer_info"]["peer_id"].stringValue
//                        Configuration.host = _JSON["data"]["peer_info"]["host"].stringValue
//                        Configuration.path = _JSON["data"]["peer_info"]["path"].stringValue
//                        Configuration.port = _JSON["data"]["peer_info"]["port"].intValue
//                        Configuration.key = _JSON["data"]["peer_info"]["key"].stringValue
//                        Configuration.tokenPeerID = tokenOauth
//
//                        let stun = PeerIceServerOptions(url: _JSON["data"]["ice_server"][0]["stun"]["url"].stringValue, username: _JSON["data"]["ice_server"][0]["stun"]["username"].stringValue, credential: _JSON["data"]["ice_server"][0]["stun"]["credential"].stringValue)
//                        let turn = PeerIceServerOptions(url: _JSON["data"]["ice_server"][0]["turn"]["url"].stringValue, username: _JSON["data"]["ice_server"][0]["turn"]["username"].stringValue, credential: _JSON["data"]["ice_server"][0]["turn"]["credential"].stringValue)
//                        Configuration.iceServerOptions = [stun, turn]
//                        completion(tokenOauth)
//                    }else{
//                        completion("NOTTOKEN")
//                    }
//                }) {
//                    completion("NOTTOKEN")
//                }
//            }
//        }
//    }
//
//
//    public class func showCallVideoNF(ViewController: UIViewController, startCalling: Bool, userID: String, token: String, tokenCallPeer: String) {
//
//        appVar.startCalling = true
//
//        appVar.userID = userID
//        appVar.token = token
//        appVar.tokenCallPeer = tokenCallPeer
//        print("Khoi tao callvideo")
//        if let urlString = Bundle.main.path(forResource: "VideoCallNFKit", ofType: "framework", inDirectory: "Frameworks") {
//            print("GET LINK CALL")
//            let bundle = (Bundle(url: NSURL(fileURLWithPath: urlString) as URL))
//            let sb = UIStoryboard(name: "Home", bundle: bundle)
//            let vc = sb.instantiateViewController(withIdentifier: "VideoCallID")
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                vc.modalPresentationStyle = .fullScreen
//                ViewController.present(vc, animated: false, completion: nil)
//            }
//        }
//    }
//
//}
//
//
