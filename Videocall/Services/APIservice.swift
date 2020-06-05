//
//  APIservice.swift
//  VideoCallNFKit
//
//  Created by NhatNguyen on 2/19/20.
//  Copyright © 2020 NhatNguyen. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
private var sessionManager: SessionManager?

enum APIVideoCallservice:String {
    
    case getOauthToken = "/access-token"
    case getpeerServerInfo = "/peers/info"
    case getpeerServerIce = "/peers/ice-server"
    case getNotifyVideoCall = "/calls/check-time-working"
    case getPeerID = ""
    
    private func enableCertificatePinning() {
//      let certificates: [SecCertificate] = []
      let certificates = getCertificates()
      let trustPolicy = ServerTrustPolicy.pinCertificates(certificates: certificates, validateCertificateChain: false, validateHost: true)
      let trustPolicies = [ "api-live.lian.vn": trustPolicy ]
      let policyManager =  ServerTrustPolicyManager(policies: trustPolicies)
      sessionManager = SessionManager( configuration: .default, serverTrustPolicyManager: policyManager)
    }
    
    private func getCertificates() -> [SecCertificate] {
        let urlCer = URL(fileURLWithPath: "\(appVar.sdkPathLink)/videokyc.cer")
        let localCertificate = try! Data(contentsOf: urlCer) as CFData
        guard let certificate = SecCertificateCreateWithData(nil, localCertificate)
           else { return [] }
        
        let urlCerNew = URL(fileURLWithPath: "\(appVar.sdkPathLink)/gs.videokyc.vn.der")
        let localCertificateNew = try! Data(contentsOf: urlCerNew) as CFData
        guard let certificateNew = SecCertificateCreateWithData(nil, localCertificateNew)
           else { return [] }

        return [certificate, certificateNew]
    }
    
    func getPeerjs(parameters:String, headers: HTTPHeaders, success:@escaping (_ response : Data)->(), failure : @escaping (_ error : Error)->()){
            let url = "\(parameters)"
//            print(url)
            enableCertificatePinning()
            sessionManager?.request(url, method: .get, encoding: URLEncoding.default, headers: headers).responseString { (response) in
                switch response.result {
                case .success:
                    if let data = response.data {
                        success(data)
                    }
                case .failure(let error):
                    failure(error)
                }
            }
        }
    
    func get(parameters:String, headers: HTTPHeaders, success:@escaping (_ response : Data)->(), failure : @escaping (_ error : Error)->()){
        let url = "\(appVar.apiServer)\(self.rawValue)?\(String(describing: parameters))"
//        print(url)
        enableCertificatePinning()
        sessionManager?.request(url, method: .get, encoding: URLEncoding.default, headers: headers).responseJSON { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
//                    print("success api \(data)")
                    success(data)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    func post(postFields: [String : Any], success:@escaping (_ response : Data)->(), failure : @escaping (_ error : Error)->()){
        let url = "\(appVar.apiServer)\( self.rawValue)"
        let headers: HTTPHeaders = [
            /* "Authorization": "your_access_token",  in case you need authorization header */
            "Content-type": "application/x-www-form-urlencoded"
        ]
        
        enableCertificatePinning()
        sessionManager?.request(url, method: .post, parameters: postFields, encoding: URLEncoding.httpBody, headers: headers).responseJSON { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
                    success(data)
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

}
