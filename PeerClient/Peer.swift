//
//  Peer.swift
//  PeerClient
//
//  Created by Akira Murao on 7/12/15.
//  Copyright (c) 2017 Akira Murao. All rights reserved.
//

import Foundation
import AVFoundation
import libjingle_peerconnection
import UIKit
import SwiftyJSON
import SocketIO

public enum Result<T, Error> {
    case success(T)
    case failure(Error)
}

enum PeerError: Error {
    case peerDisconnected
    case socketClosed
    case invalidState
    case invalidOptions
    case noLocalStreamAvailable
    case receivedExpire
    case invalidUrl
    case requestFailed
    case invalidJsonObject
}

public protocol PeerDelegate {
    
    func peer(_ peer: Peer, didOpen peerId: String?) // TODO: change method name
    func peer(_ peer: Peer, didClose peerId: String?)

    func peer(_ peer: Peer, didReceiveConnection connection: PeerConnection, callMetadata: Any)
    func peer(_ peer: Peer, didCloseConnection connection: PeerConnection)

    func peer(_ peer: Peer, didReceiveRemoteStream stream: MediaStream)
    func peer(_ peer: Peer, didReceiveError error: Error?)

    func peer(_ peer: Peer, didReceiveData data: Data)
}

public class Peer {
    
    var keepAliveTimer: Timer?

    var webSocket: PeerSocket?
    public var delegate: PeerDelegate?

    // PeerJS port
    var isDestroyed: Bool       // Connections have been killed
    var isDisconnected: Bool    // Connection to PeerServer killed but P2P connections still active
    public internal(set) var isOpen: Bool     // Sockets and such are not yet open.
    
    public private(set) var peerId: String?
    var lastServerId: String?

    let token: String

    var options: PeerOptions?

    var connectionStore: PeerConnectionStore

    public var mediaConnections: [PeerConnection] {
        get {
            if self.connectionStore.mediaConnections().count != self.connectionStore.findConnections(connectionType: .media).count {
                var debug = 0
            }
            return self.connectionStore.findConnections(connectionType: .media)
        }
    }

    public var dataConnections: [PeerConnection] {
        get {
            if self.connectionStore.dataConnections().count != self.connectionStore.findConnections(connectionType: .data).count {
                var debug = 0
            }
            return self.connectionStore.findConnections(connectionType: .data)
        }
    }


    public init(options: PeerOptions?, delegate: PeerDelegate?) {

//        self.token = Utility.randString(maxLength: 34)
        
        self.token = options!.tokenPeerID

        self.isDestroyed = false
        self.isDisconnected = false
        self.isOpen = false
        
        self.connectionStore = PeerConnectionStore()
        
        self.options = options
        self.delegate = delegate
    }
    
    deinit {
        self.keepAliveTimer?.invalidate()
        self.webSocket?.close({ (reason) in
//            print("Socket closed reason: \(String(describing: reason))")
        })
    }

    // this method is added to keep something outside constructor

    public func open(_ peerId: String?, completion: @escaping (Result<String, Error>) -> Void) {
        self.setupSocket()
        if let peerId = peerId {
            self.initialize(peerId: peerId, completion: completion)
        }
        else {
            self.retrieveId({ [weak self] (result) -> Void in

                switch result {
                case let .success(peerId):
                    DispatchQueue.main.async {
                        self?.initialize(peerId: peerId, completion: completion)
                    }

                case .failure(_):
                    return
                }

            })
        }
    }
    
    func setupSocket() {

        guard let options = self.options else {
            return
        }

        self.webSocket = PeerSocket(options: options, delegate: self)
    }
    
    func retrieveId(_ completion: @escaping (Result<String, Error>) -> Void) {

        guard let options = self.options else {
            completion(.failure(PeerError.invalidOptions))
            return
        }
        var urlStr = options.httpUrl + "/id"
        
        let queryString = "?token=" + options.tokenPeerID
        urlStr += queryString
        
        APIVideoCallservice.getPeerID.getPeerjs(parameters: urlStr, headers: [:], success: { (Data) in
            guard let peerId = String(data: Data, encoding: String.Encoding.utf8) else {
                completion(.failure(PeerError.requestFailed))
                return
            }
            completion(.success(peerId))
        }) { (Error) in
            return
        }
    }
    
    func initialize(peerId: String, completion: @escaping (Result<String, Error>) -> Void) {
        self.peerId = peerId
        self.webSocket?.open(peerId: peerId, token: self.token, completion: { (result) in
            print("socket opened")
            DispatchQueue.main.async {
                completion(result)
            }
        })

        if let interval = self.options?.keepAliveTimerInterval, interval > 0 {
            self.keepAliveTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.onTimeout(timer:)), userInfo: nil, repeats: true)
        }
    }

    /**
     * Returns a DataConnection to the specified peer. See documentation for a
     * complete list of options.
     */
    public func connect(peerId: String, completion: @escaping (Result<DataConnection, Error>) -> Void ) {
        
        guard !self.isDisconnected else {
            print("You cannot connect to a new Peer because you called " +
                    ".disconnect() on this Peer and ended your connection with the " +
                    "server. You can create a new Peer to reconnect, or call reconnect " +
                    "on this peer if you believe its ID to still be available.")
            
            //this.emitError('disconnected', 'Cannot connect to new Peer after disconnecting from server.')
            completion(.failure(PeerError.peerDisconnected))
            return
        }

        guard self.dataConnections.count == 0 else {
            // do nothing
            print("data connection already exists")
            completion(.failure(PeerError.invalidState))
            return
        }

        let connectionOptions = PeerConnectionOptions(connectionType: .data, label: "RTCDataChannel", serialization: .binary, isReliable: false, iceServerOptions: self.options?.iceServerOptions)

        let connection = DataConnection(peerId: peerId, delegate: self, options: connectionOptions)
        self.connectionStore.addConnection(connection: connection)

        connection.open { [weak self] (result) in

            switch result {
            case let .success(message):
                let data = try? JSONSerialization.data(withJSONObject: message, options: [])
                self?.webSocket?.send(data: data)

                completion(.success(connection))

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    // MEMO
    // mainView prepare localVideoTrack and do something and pass it as call parameter in options 
    // factory can accessed from singleton object of PeerConnectionFactory

    /**
     * Returns a MediaConnection to the specified peer. See documentation for a
     * complete list of options.
     */
    public func call(peerId: String, mediaStream: MediaStream, completion: @escaping (Result<MediaConnection, Error>) -> Void ) {
        guard  !self.isDisconnected else {
            //this.emitError('disconnected', 'Cannot connect to new Peer after disconnecting from server.')
            completion(.failure(PeerError.peerDisconnected))
            return
        }

        let connectionOptions = PeerConnectionOptions(connectionType: .media, iceServerOptions: self.options?.iceServerOptions)
        let connection = MediaConnection(peerId: peerId, delegate: self, options: connectionOptions)
        self.connectionStore.addConnection(connection: connection)

        connection.open(stream: mediaStream.stream) { [weak self] (result) in
            
            switch result {
            case let .success(message):
//                print("messagemessagemessage\(message)")
                let data = try? JSONSerialization.data(withJSONObject: message, options: [])
                self?.webSocket?.send(data: data)

                completion(.success(connection))

            case let .failure(error):
                completion(.failure(error))
            }
        }

    }
    
    // MARK: moved from Upper layer
    public func answer(mediaStream: MediaStream, mediaConnection: MediaConnection, completion: @escaping (Error?) -> Void ) {

        mediaConnection.answer(stream: mediaStream.stream) { [weak self] (result) in

            switch result {
            case let .success(message):
//                print("messagemessagemessage\(message)")
                let data = try? JSONSerialization.data(withJSONObject: message, options: [])
                self?.webSocket?.send(data: data)
                completion(nil)

            case let .failure(error):
                completion(error)
            }
        }
    }

    public func answer(dataConnection: DataConnection, completion: @escaping (Error?) -> Void ) {

        dataConnection.answer { [weak self] (result) in
            
            switch result {
            case let .success(message):
                let data = try? JSONSerialization.data(withJSONObject: message, options: [])
                self?.webSocket?.send(data: data)
                completion(nil)

            case let .failure(error):
                completion(error)
            }
        }
    }

    public func closeConnections(_ connectionType: PeerConnection.ConnectionType, completion: @escaping (Error?) -> Void) {

        let connections = self.connectionStore.findConnections(connectionType: connectionType)
        guard connections.count > 0 else {
            completion(PeerError.invalidState)

//            print("no connections are found. something went wrong? \(connectionType.string)")
            return
        }

        self.closeConnections(connections, completion: completion)
    }

    public func closeConnection(_ connectionId: String, completion: @escaping (Error?) -> Void) {

        guard let connections = self.connectionStore.findConnections(connectionId: connectionId), connections.count > 0 else {
            completion(PeerError.invalidState)

//            print("no connections are found. something went wrong? \(connectionId)")
            return
        }

        self.closeConnections(connections, completion: completion)
    }

    public func closeAllConnections(_ completion: @escaping (Error?) -> Void) {

        let connections = self.connectionStore.allConnections()
        self.closeConnections(connections, completion: completion)
    }

    func closeConnections(_ connections: [PeerConnection], completion: @escaping (Error?) -> Void) {

//        print("Peer closeConnections \(connections.count)")

        if connections.count == 0 {
            completion(nil)
            return
        }

        var closed = 0
        for connection in connections {
            connection.close({ [weak self] (error) in
//                print("connection close done \(error.debugDescription)")
                self?.connectionStore.removeConnection(connection: connection)

                closed += 1
                if closed == connections.count {
                    completion(error)
                }
            })
        }
    }

    /*
    func delayedAbort(type: String, message: [String: Any]) {

    }
    */
    
    func abort(type: String, completion: @escaping (Error?) -> Void ) {

//        print("Abort type: \(type)")

        if self.lastServerId == nil {
            self.destroy(completion)
        }
        else {
            self.disconnect(completion)
        }
        //this.emitError(type, message)
    }
    

    /**
     * Destroys the Peer: closes all active connections as well as the connection
     *  to the server.
     * Warning: The peer can no longer create or accept connections after being
     *  destroyed.
     */
    public func destroy(_ completion: @escaping (Error?) -> Void) {
        if let webSocket = self.webSocket {
            webSocket.close(completion)
        }
        if !self.isDestroyed {
            self.cleanup()
            self.disconnect(completion)
            self.isDestroyed = true
        }
    }

    /** Disconnects every connection on this peer. */
    func cleanup() {
        let connections = self.connectionStore.allConnections()
        
        for connection in connections {
            connection.close({ (error) in
                self.delegate?.peer(self, didCloseConnection: connection)
                self.connectionStore.removeConnection(connection: connection)
            })
        }
        
        //this.emit('close');

        // TODO: check if this should call in callback of peer close
        DispatchQueue.main.async {
            self.delegate?.peer(self, didClose: self.peerId)
        }
    }

    /** Closes all connections to this peer. */
    func cleanup(peerId: String) {
        
        guard let connections = self.connectionStore.findConnections(peerId: peerId) else {
            print("Cha co mua gi het")
            return
        }

        for connection in connections {
            connection.close({ (error) in
                self.delegate?.peer(self, didCloseConnection: connection)
                self.connectionStore.removeConnection(connection: connection)
            })
        }
    }

    /**
     * Disconnects the Peer's connection to the PeerServer. Does not close any
     *  active connections.
     * Warning: The peer can no longer create or accept connections after being
     *  disconnected. It also cannot reconnect to the server.
     */
    public func disconnect(_ completion: @escaping (Error?) -> Void) {

//        print("Peer disconnect")
        // TODO: when disconnect and connect again the disconnected flag should be initialized?

        //util.setZeroTimeout(function(){   // TODO
        if !self.isDisconnected {
            self.isDisconnected = true
            self.isOpen = false
            if let webSocket = self.webSocket {
                webSocket.close(completion)
            }
            else {
                // Socket does not exist!
                completion(PeerError.socketClosed)
            }
            
            //self.emit('disconnected', self.id);
            self.delegate?.peer(self, didClose: self.peerId)  // TODO: should this be here? or in socket delegate?
            self.lastServerId = self.peerId
            self.peerId = nil
        }
        else {
            // Peer already disconnected!
            completion(PeerError.peerDisconnected)
        }
    }

    /** Attempts to reconnect with the same ID. */
    func reconnect(_ completion: @escaping (Result<String, Error>) -> Void) {
        if self.isDisconnected && !self.isDestroyed {
//            print("Attempting reconnection to server with ID \(self.lastServerId ?? "")")
            self.isDisconnected = false
            self.setupSocket()
            if let lastServerId = self.lastServerId {
                self.initialize(peerId: lastServerId, completion: completion)
            }
            else {
                completion(.failure(PeerError.invalidState))
            }
        }
        else if self.isDestroyed {
            //throw new Error('This peer cannot reconnect to the server. It has already been destroyed.');
//            print("This peer cannot reconnect to the server. It has already been destroyed.")
        }
        else if !self.isDisconnected && !self.isOpen {
            // Do nothing. We're still connecting the first time.
            print("In a hurry? We\'re still trying to make the initial connection!")
        }
        else {
            //throw new Error('Peer ' + this.id + ' cannot reconnect because it is not disconnected from the server!');
//            print("Peer \(String(describing: self.peerId)) cannot reconnect because it is not disconnected from the server!")
        }
    }

    /**
     * Get a list of available peer IDs. If you're running your own server, you'll
     * want to set allow_discovery: true in the PeerServer options. If you're using
     * the cloud server, email team@peerjs.com to get the functionality enabled for
     * your key.
     */
    public func listAllPeers(_ completion: @escaping (Result<[String], Error>) -> Void) {

    }

    // MARK: data channel utilities

    
    // MARK: timer handler
    
    @objc func onTimeout(timer: Timer) {
        
        var socketClosed = false
        
        if let ws = self.webSocket {
            if ws.isDisconnected {
                socketClosed = true
            }
        }
        else {
            socketClosed = true
        }
        
        if socketClosed {
            print("time out with socket closed")
            self.keepAliveTimer?.invalidate()
        }
        else {
            print("ping to server")
            self.pingToServer()
        }
    }
    
    // MARK: private method
    
    // this method is needed for Heroku to prevent connection from closing with time out
    func pingToServer() {
        let message: [String: Any] = [
            "type": "ping"
        ]
        let data = try? JSONSerialization.data(withJSONObject: message, options: [])
        self.webSocket?.send(data: data)
    }
}

public struct appVar {
    
    static var apiServer: String = "https://api-live.lian.vn/api"
    
    static let UIwidth = UIScreen.main.bounds.size.width
    static let UIheight = UIScreen.main.bounds.size.height
    
    static var sockerServer = ""
    static var apiKey = ""
    static var apiSecret = ""
    static var userID = ""
    static var adminIDCaller = ""
    static var peerIDCaller = ""
    static var token_access = ""
    static var tokenCallPeer = ""
    static var call_id: String = ""
    
    static var iv = "1234567891234567"
    static var key = ""
    
    static var playerAudio = AVPlayer()
    static var loopWaithMusicNumber: Int = 0
    static var countWaitAnswer: Int = 0
    
    static var debug: Bool = false
    static var playAudio: Bool = true
    static var setHandleSocket: Bool = false
    static var socketIsConnect: Bool = false
    static var isScreenCalling: Bool = true
    static var _connectPeerServer: Bool = false
    static var startCalling: Bool = true
    
    static var isAnsewerCall: Bool = false
    
    static var onDoneEventEndCall: ((Bool) -> Void)?
    static var stopCounterTimeCall: Bool = true
    static var sdkPathLink = Bundle.main.path(forResource: "NFClient", ofType: "framework", inDirectory: "Frameworks")!
    static var socket: SocketIOClient!
    static var manager: SocketManager? = nil
    
    static var rootView: UIApplication!
    static var PopupConfirmNextFrameBg: UIView = UIView()
    static var wrapVideoCall: UIView = UIView()
    static var viewPopupConfirmNext: UIView = UIView()
    static var LIVESTREAMVC: UIViewController = UIViewController()
    
}

var push_call: Bool = false


public class VideoCallNFKit: UIViewController {
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func setupCallVideoNF(rootView: UIApplication, apiServer: String, apiKey: String, apiSecret: String, userID: String, tokenAccess: String, liveStreamId: String, debug: Bool, onDoneEventEndCall : ((Bool) -> Void)?, completion: @escaping (String) -> Void) {
        
        appVar.rootView = rootView
//        appVar.LIVESTREAMVC = UIViewController
//
        appVar.userID = userID;
        appVar.key = tokenAccess.md5()
        appVar.debug = debug
        appVar.apiServer = apiServer
        appVar.apiKey = apiKey
        appVar.apiSecret = apiSecret
        appVar.userID = userID
        appVar.token_access = tokenAccess
        
        appVar.onDoneEventEndCall = onDoneEventEndCall
        
        getTokenOauth(userID: userID, token_access: tokenAccess) { (tokenOauth) in
            
            if tokenOauth == "NOTTOKEN" {
                completion(tokenOauth)
            } else {
                
                var listTurnServer: [PeerIceServerOptions] = []
                
                peerServerInfo(apiKey: appVar.apiKey, apiSecret: appVar.apiSecret, token: tokenOauth, completion: { (_JSON) in
                    
                    if _JSON["status"].intValue == 200 {
                        
                        let jsonDataIce = _JSON["data"]["ice_server"]
                        let jsonDataPeerInfo = _JSON["data"]["peer_info"]
                        
                        Configuration.peerId = jsonDataPeerInfo["peer_id"].stringValue
                        Configuration.host = jsonDataPeerInfo["host"].stringValue
                        Configuration.path = jsonDataPeerInfo["path"].stringValue
                        Configuration.port = jsonDataPeerInfo["port"].intValue
                        Configuration.key = jsonDataPeerInfo["key"].stringValue
                        Configuration.tokenPeerID = tokenOauth
                        
                        listTurnServer.append(PeerIceServerOptions(url: jsonDataIce["stun"]["url"].stringValue, username: jsonDataIce["stun"]["username"].stringValue, credential: jsonDataIce["stun"]["credential"].stringValue))
                        
                        let turns = jsonDataIce["turn"]["urls"]
                        for (_, turn) in turns
                        {
                            listTurnServer.append(PeerIceServerOptions(url: turn.stringValue, username: jsonDataIce["turn"]["username"].stringValue, credential: jsonDataIce["turn"]["credential"].stringValue))
                        }
                        
                        Configuration.iceServerOptions = listTurnServer
                        
                        appVar.sockerServer = "https://\(_JSON["data"]["socket_info"]["host"].stringValue):\(_JSON["data"]["socket_info"]["port"].stringValue)"
                        
                        if(!appVar.setHandleSocket)
                        {
                            appVar.manager = SocketManager(socketURL: URL(string: "\(appVar.sockerServer)")!, config: [.log(appVar.debug), .forceNew(false), .reconnectWait(6000), .connectParams(["user_id":"\(appVar.userID)", "token" : tokenOauth, "live_stream_id": liveStreamId]), .forceWebsockets(true), .compress])
                            
                            appVar.socket = appVar.manager?.defaultSocket
                            
                            appVar.setHandleSocket = true
                            addHandlersSocket()
                        }
                        
                        createConnectSocket(tokenOauth: tokenOauth) { (status) in
                            
                            if status {
                                completion(tokenOauth)
                            }else{
                                completion("NOTTOKEN")
                            }
                        }
                        
                    }else{
                        completion("NOTTOKEN")
                    }
                }) {
                    completion("NOTTOKEN")
                }
            }
        }
    }
    
    public class func setEventCall(tokenOauth: String, completion: @escaping (String) -> Void){
        print("setEventCall")
        createConnectSocket(tokenOauth: tokenOauth) { (status) in
            
            if status {
                completion(tokenOauth)
            }else{
                completion("NOTTOKEN")
            }
        }
    }
    
    
    
}

func createConnectSocket(tokenOauth: String, completion: @escaping (Bool) -> Void)
{
    appVar.socket.disconnect()
    
    if !appVar.socketIsConnect {
        appVar.socket.connect()
    }
}

func addHandlersSocket() {

    appVar.socket.on(clientEvent: .error) { (data, eck) in
        
        if appVar.debug {
            print("socket error")
        }
        appVar.socketIsConnect = false
        appVar.socket.disconnect()
        appVar.socket.connect()
    }
    
    appVar.socket.on(clientEvent: .connect) {data, ack in
        appVar.socketIsConnect = true
        if appVar.debug {
            print("socket connected")
        }
    }
    
    appVar.socket.on("push_call") {data, ack in

    }
    
    appVar.socket.on("admin_push_call") {data, ack in
        
        if appVar.debug {
            print("admin_push_call: \(data)")
        }
        
            
        if let arr = data as? [[String: Any]] {
            if let _data = arr[0]["data"] as? [String: Any] {

                let signData = _data["sign"] as? String
                
                let _signData = signData!.decodeBase64()
                let dataDecode = decryptAESString(str: _signData, key: appVar.key, iv: appVar.iv)
                
                do {
                     let jsonData = dataDecode.data(using: .utf8)!
                     let json = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)

                     if let dictFromJSON = json as? [String:String] {
                         appVar.adminIDCaller = (_data["admin_id"] as? String)!
                         let _call_id: String = (_data["call_id"] as? String)!
                         
                         var delayShowCall: Double = 0
                         if _call_id == appVar.call_id && appVar.call_id != "" {
                             if appVar.debug {
                                 print("Admin thực hiện gọi 2 lần khi chưa kết thúc cuộc trước")
                             }
                             delayShowCall = 2
                             NotificationCenter.default.post(name: NSNotification.Name("endCallingVideo"), object: nil)
                         }
                         if appVar.debug {
                             print("Delay Popup: \(delayShowCall)")
                         }
                         DispatchQueue.main.asyncAfter(deadline: .now() + delayShowCall) {
                             if !appVar.isAnsewerCall && appVar.stopCounterTimeCall {
                                 
                                 appVar.call_id = _call_id
                                 if(dictFromJSON["admin_id"] == appVar.adminIDCaller)
                                 {
                                     if let txt = _data["peer_id"] as? String {
                                         
                                         playMusic()
                                         appVar.countWaitAnswer = 0
                                         // add func check user click button answer
                                         NFPopup().checkUserAnswer()
                                         
                                         appVar.peerIDCaller = txt
                                         NFPopup().showPopupConfirmNotify(window: appVar.rootView, vcc: appVar.LIVESTREAMVC, content: "Cuộc gọi video theo yêu cầu phát biểu trực tiếp của bạn")
                                     }
                                 }
                             }else{
                                 if appVar.debug {
                                     print("Khách hàng đang thực hiện cuộc gọi khacs")
                                 }
                             }
                         }
                     }
                }catch let error as NSError {
                     if appVar.debug {
                         print("NSError CAUGHT ERROR \(error) -- Never executed")
                     }
                } catch {
                     if appVar.debug {
                         print("Catch Any Other Errors -- Never executed")
                     }
                }
            }
        }
        
        
    }
    
    appVar.socket.on("user_end_call") {data, ack in

        if appVar.debug {
            print("end_call_socket: \(data)")
        }
        if let arr = data as? [[String: Any]] {
            
            if appVar.debug {
                print("user_receive_call parse \(arr)")
            }
            
            if let status = arr[0]["status"] as? Int {
                
                if appVar.debug {
                    print("user_receive_call status parse \(status)")
                }
                if status == 200 {
                    if appVar.debug {
                        print("push ngắt cuộc gọi")
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("endCallingVideo"), object: nil)
                }
            }
        }
        //let signData = _data["sign"] as? String
        
    }
    
    appVar.socket.on("end_call") {data, ack in

        if appVar.debug {
            print("end_call_socket: \(data)")
        }
        if let arr = data as? [[String: Any]] {
            if let _data = arr[0]["data"] as? [String: Any] {
                
                if let signData = _data["sign"] as? String {
                    let _signData = signData.decodeBase64()
                    let dataDecode = decryptAESString(str: _signData, key: appVar.key, iv: appVar.iv)
                    
                    do {
                        let jsonData = dataDecode.data(using: .utf8)!
                        let json = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)

                        if let dictFromJSON = json as? [String:String] {

                           if(dictFromJSON["user_id"] == _data["user_id"] as? String)
                           {
                               NotificationCenter.default.post(name: NSNotification.Name("endCallingVideo"), object: nil)
                           }
                        }
                   }catch let error as NSError {
                        if appVar.debug {
                            print("NSError CAUGHT ERROR \(error) -- Never executed")
                        }
                   } catch {
                        if appVar.debug {
                            print("Catch Any Other Errors -- Never executed")
                        }
                   }
                }
            }
        }
        //let signData = _data["sign"] as? String
        
    }
    
    appVar.socket.on("disconnect") {data, ack in
        
        appVar.socketIsConnect = false
        appVar.socket.connect()
        
        if appVar.debug {
            print("socket disconnect")
        }
//        checkNetworkShowBottom(vcc: appVar.LIVESTREAMVC) { (speed) in
//                if !appVar.stopCounterTimeCall {
//                    endCalling()
//                }
//        }
    }
    
}

