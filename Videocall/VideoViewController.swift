//
//  VideoViewController.swift
//  VideoCallNFKit
//
//  Created by NhatNguyen on 2/13/20.
//  Copyright © 2020 NhatNguyen. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import SocketIO
import SwiftyJSON

class VideoViewController: UIViewController {

    @IBOutlet weak var notifyVideo: UIView!
    @IBOutlet weak var txtNotifyVideo: UILabel!
    @IBOutlet weak var image_wait: UIImageView!
    @IBOutlet weak var controlView: UIView!
    var _peer: Peer?
    var peer: Peer? {
        get {
           if _peer == nil {
            let peerOptions = PeerOptions(key: Configuration.key, host: Configuration.host, path: Configuration.path, secure: Configuration.secure, port: Configuration.port, tokenPeerID: Configuration.tokenPeerID, iceServerOptions: Configuration.iceServerOptions!)
               peerOptions.keepAliveTimerInterval = Configuration.herokuPingInterval

               _peer = Peer(options: peerOptions, delegate: self)
           }

           return _peer
        }

        set {
           _peer = newValue
        }
    }
    
    
    var callInfo: CallInfo?
    
//    @IBOutlet weak var exitVideoViewButton: UIButton!
    @IBOutlet weak var statusCall: UILabel!
    @IBOutlet weak var remoteVideoContainerView: UIView!
    @IBOutlet weak var localVideoContainerView: UIView!
    @IBOutlet weak var mute_audio_button: UIButton!
    @IBOutlet weak var unmute_audio_button: UIButton!
    
    @IBOutlet weak var lableNameCallcenter: UILabel!
    
    var localVideoView: EAGLVideoView!
    var remoteVideoView: EAGLVideoView!

    lazy var localVideoTrack: VideoTrack? = nil
    lazy var remoteVideoTrack: VideoTrack? = nil
    lazy var localVideoSize: CGSize = CGSize.zero
    lazy var remoteVideoSize: CGSize = CGSize.zero
    
    var deviceName: Int = 2
    var camState: Int = 2
    var camOldState: Int = 2
    var numberHiddenControl: Int = 0
    
    let kLocalViewPadding: CGFloat = 10
    var minute = 0;
    var seconds = 0;
    
    var isRequestCallingState: Bool = true
    var isHiddenControlState: Bool = true
    var isMuteAudio: Bool = false
    var isSetMuteAudio: Bool = false
    var isCallChat: Bool = false
    var playAudioWait: Bool = true
    var startPlayAudioWait: Bool = true
    var stopCounterTimeCall: Bool = false
    
    var notInternet: Bool = false
    
    let factory = PeerConnectionFactory.sharedInstance
    
    var mediaStream: MediaStream? = nil
    var localMediaStream: MediaStream?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // show trạng thái
//        showNotifyVideoCall()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(VideoViewController._didBecomeActiveNotification(notfication:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default
         .addObserver(self,
                      selector: #selector(endCallingVideoAction),
        name: NSNotification.Name ("endCallingVideo"),
        object: nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(VideoViewController.orientationChanged(notification:)),
        name: UIDevice.orientationDidChangeNotification,
        object: nil)
        
        remoteVideoContainerView.isHidden = true
        
        if isSetMuteAudio {
            self.setImageMute()
        }
        
        self.localVideoView = EAGLVideoView(frame: self.localVideoContainerView.bounds)
        localVideoView.isHidden = true
        self.localVideoView.delegate = self
        localVideoView.transform = CGAffineTransform(rotationAngle: CGFloat(90 * M_PI/180));
//        localVideoView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        localVideoView.layer.cornerRadius = 4
        
        self.localVideoContainerView.addSubview(self.localVideoView)
        self.localVideoContainerView.layer.shadowPath = UIBezierPath(rect: localVideoContainerView.bounds).cgPath
        self.localVideoContainerView.layer.shadowRadius = 10
        self.localVideoContainerView.layer.shadowOffset = .zero
        self.localVideoContainerView.layer.shadowOpacity = 1
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTapShowControl(_:)))
        self.remoteVideoView = EAGLVideoView(frame: self.remoteVideoContainerView.bounds)
        self.remoteVideoView.delegate = self
        self.remoteVideoView.transform = CGAffineTransform(scaleX: -1, y: 1)
        self.remoteVideoView.addGestureRecognizer(tap)
        self.remoteVideoContainerView.addSubview(self.remoteVideoView)
        
        let factory = PeerConnectionFactory.sharedInstance
        let deviceName: Int = 2
        mediaStream = factory.createLocalMediaStream(_deviceCameraName: deviceName)!
        // Mở loa ngoài.
        setSpeakerStates(enabled: true)
        
    }
    
    deinit {
        appVar.loopWaithMusicNumber = 0
        endMusicWait()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appVar.loopWaithMusicNumber = 0
        appVar.socket.disconnect()
        
        DispatchQueue.main.async {
            endMusicWait()
            self.minute = 0;
            self.seconds = 0;
            self.camState = 2
            self.stopCounterTimeCall = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !appVar._connectPeerServer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.connectToSignailingServer()
            }
        }
        
        NFPopup().iDismiss { (status) in }
        
        self.minute = 0;
        self.seconds = 0;
        stopCounterTimeCall = false
        
    }
 
    @objc func endCallingVideoAction(_ notification: Notification)
    {
        if appVar.debug {
            print("endCallingVideo from Notification")
        }

        self.endCalling()

    }
    
    @objc func orientationChanged(notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let factory = PeerConnectionFactory.sharedInstance
            factory.changeCameraData(self.camOldState)
        }
    }
    
    @objc func _didBecomeActiveNotification(notfication: NSNotification)
    {
        let factory = PeerConnectionFactory.sharedInstance
        factory.changeCameraData(camOldState)
        checkNetworkShowBottom(vcc: self) { (speed) in
            
            if speed {
                if self.notInternet {
                    self.endCalling()
                }
            } else {
                self.notInternet = true
            }
        }
    }
    
    func countEndWaitCall()
    {
        if playAudioWait && startPlayAudioWait {
//            print("playAudioWaitWithLink: start")
            startPlayAudioWait = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.seconds = self.seconds + 1;
            if(self.seconds > 130 && !self.isCallChat)
            {
                self.endCalling()
            }else{
                self.countEndWaitCall()
            }
        }
    }
    
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
//        print("notenotenotenote\(note)")
        startPlayAudioWait = true
    }
    
    @objc func handleTapShowControl(_ sender: UITapGestureRecognizer? = nil) {
        controlView.isHidden = false
    }
    
    
    @IBAction func endcall(_ sender: Any) {
        showConfirmEndCall(vcc: self) { (statusConfirm) in
            if statusConfirm {
                NFPopup().showProcessingLoading(vcc: self, content: "Vui lòng chờ trong giây lát")
                
                if appVar.debug {
                    print("end_call_endCalling")
                }
                appVar.socket.emit("user_end_call", ["user_id": appVar.adminIDCaller, "sign": encryptAESString(str: appVar.adminIDCaller, key: appVar.key, iv: appVar.iv)]);
                
            }
        }
    }
    
    func endCalling()
    {
        appVar.call_id = ""
        appVar.socketIsConnect = false
        setSpeakerStates(enabled: false)
        endMusicWait()
        self.peer = nil
        self.minute = 0;
        self.seconds = 0;
        
        guard let peer = self.peer else {
            return
        }
        
        peer.closeConnections(.media, completion: { [weak self] (error) in
            
            self!.remoteVideoTrack = nil
            appVar.isAnsewerCall = false
            appVar._connectPeerServer = false
            appVar.stopCounterTimeCall = true
            appVar.startCalling = false
            
            self!.peer = nil
            self!.minute = 0;
            self!.seconds = 0;
            
            self!.dismiss(animated: false) {
                appVar.onDoneEventEndCall!(true)
            }
        })

    }
    
    
    @IBAction func changecamera(_ sender: Any) {
        changeCameraFactory()
    }
    
    func changeCameraFactory()
    {
//        print("camStatecamState\(camState)")
        let factory = PeerConnectionFactory.sharedInstance
        camOldState = camState
        factory.changeCameraData(camState)
        if camState == 1 {
            camState = 2
        }else if camState == 2{
            camState = 1
        }
    }
    
    @IBAction func muteAudo(_ sender: Any) {
        isSetMuteAudio = true
        setImageMute()
    }
    
    @IBAction func unmuteAudio(_ sender: Any) {
//        isSetMuteAudio = false
//        setImageMute()
    }
    
    
    func setImageMute()
    {
        if !isMuteAudio {
            unmute_audio_button.isHidden = false
            isMuteAudio = true
            
            let factory = PeerConnectionFactory.sharedInstance
            factory.disableMicrophoneData()
        
        }else{
            let factory = PeerConnectionFactory.sharedInstance
            factory.enableMicrophoneData()
            
            unmute_audio_button.isHidden = true
            isMuteAudio = false
        }
    }
    
    func pushServerMyOnline()
    {
        if !appVar.stopCounterTimeCall {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                appVar.socket.emit("calling_verify", ["call_id": appVar.call_id, "sign": encryptAESString(str: appVar.call_id, key: appVar.key, iv: appVar.iv)]);
                self.pushServerMyOnline()
            }
        }
    }
    
    func setupRemoteMediaStream(_ mediaStream: MediaStream) {
        
        if let videoTrack = mediaStream.videoTracks.first {
            endMusicWait()
            setSpeakerStates(enabled: true)
            appVar.stopCounterTimeCall = false
            pushServerMyOnline()
            countTimeCall(label: self.statusCall, _seconds: 0, _minute: 0)
            self.remoteVideoTrack = videoTrack
            videoTrack.addVideoView(videoView: self.remoteVideoView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.image_wait.isHidden = true
                self.remoteVideoContainerView.isHidden = false
            }
        }
    }

    func answer(connection: PeerConnection, callMetadata: Any) {
        if !appVar.startCalling {
            return;
        }
        
        if let mediaConnection = connection as? MediaConnection {
            guard let peer = self.peer else {
                return
            }
            
            self.isCallChat = true
            self.playAudioWait = false
            
            self.notifyVideo.isHidden = true
            
            let callnameData = callMetadata as? [String: String]
            let nameCall: String = callnameData!["username"]!
            lableNameCallcenter.text = "NCB: \(nameCall)"
            peer.answer(mediaStream: mediaStream!, mediaConnection: mediaConnection, completion: { [weak self] (error) in
//                print(error.debugDescription)
                if error == nil {
                    appVar.stopCounterTimeCall = false
                    countTimeCall(label: self!.statusCall, _seconds: 0, _minute: 0)
                    self!.isRequestCallingState = false
                    self!.updateVideoViewLayout()
                    self?.setupLocalMediaStream(self!.mediaStream!)
                    // Auto hidden controlview timer
                    self!.autoHiddenControl()
                }
            })
        }
        
    }
    
    func call(peerId: String) {

        guard let peer = self.peer else {
            return
        }
        
//        let factory = PeerConnectionFactory.sharedInstance
//        factory.changeCameraData(self.camState)
//        self.camState = 1
//        self.camOldState = 2
//        self.updateVideoViewLayout()
//        self.setupLocalMediaStream(self.mediaStream!)
        
        peer.call(peerId: peerId, mediaStream: mediaStream!, completion: { [weak self] (result) in

            switch result {
            case .success(_):
                print("call succeeded")

                self!.updateVideoViewLayout()
                self?.setupLocalMediaStream(self!.mediaStream!)

            case let .failure(error):
                print("call failed: \(error)")
            }
        })
    }
    
    func setupLocalMediaStream(_ mediaStream: MediaStream) {
        localMediaStream = mediaStream
        if let videoTrack = mediaStream.videoTracks.first {
            self.localVideoTrack = videoTrack
            videoTrack.addVideoView(videoView: self.localVideoView)
            self.autoHiddenControl()
            
            self.localVideoView.isHidden = false
            self.localVideoView.isHidden = false
        }
    }

    func autoHiddenControl()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.numberHiddenControl = self.numberHiddenControl + 1
            if self.numberHiddenControl >= 5 {
                self.numberHiddenControl = 0
                if !self.isRequestCallingState {
                    self.controlView.isHidden = true
                }
            }
            self.autoHiddenControl()
        }
    }
        
    func connectToSignailingServer() {
        
        do {
            
            DispatchQueue.main.async {
                let factory = PeerConnectionFactory.sharedInstance
                factory.changeCameraData(self.camState)
                self.camState = 1
                self.camOldState = 2
                self.updateVideoViewLayout()
                self.setupLocalMediaStream(self.mediaStream!)
                
                self.countEndWaitCall()
            }
            
            DispatchQueue.main.async {
                
                    if self.peer == nil {
                        let peerOptions = PeerOptions(key: Configuration.key, host: Configuration.host, path: Configuration.path, secure: Configuration.secure, port: Configuration.port, tokenPeerID: Configuration.tokenPeerID, iceServerOptions: Configuration.iceServerOptions!)
                        peerOptions.keepAliveTimerInterval = Configuration.herokuPingInterval

                        self.peer = Peer(options: peerOptions, delegate: self)
                    }
                    
                    self.peer?.open(nil) { [weak self] (result) in
                        switch result {
                        case .success(_):
                            appVar._connectPeerServer = true
                            self!.call(peerId: appVar.peerIDCaller)
                            self!.isRequestCallingState = true
                            
                        case .failure(_): break
//                            print("SDK: open failed error: \(error)")
                        }
                    }
            }
        }catch _ as NSError{
            print("SDK: Éo biết lỗi gì đó ở chỗ kết nối server")
        }
        
    }
    

    func updateVideoViewLayout() {

        let defaultAspectRatio = CGSize(width: 3, height: 4)

        var localAspectRatio = self.localVideoSize
        if self.localVideoSize == CGSize.zero {
            localAspectRatio = defaultAspectRatio
        }
        var remoteAspectRatio = self.remoteVideoSize
        if self.remoteVideoSize == CGSize.zero {
            remoteAspectRatio = defaultAspectRatio
        }

//        var remoteVideoFrame = AVMakeRect(aspectRatio: remoteAspectRatio, insideRect: self.remoteVideoContainerView.bounds)
//
//        let screenHeight = UIScreen.main.bounds.size.height - self.remoteVideoSize.height
//        let videoRemoteWidth = screenHeight + self.remoteVideoSize.width
//        let marginLeftFisrt = videoRemoteWidth - videoRemoteWidth / 5
//
//        remoteVideoFrame.origin.x = 0//marginLeftFisrt - videoRemoteWidth
//        remoteVideoFrame.origin.y = 0
//        remoteVideoFrame.size.width = screenHeight + self.remoteVideoSize.width
//        remoteVideoFrame.size.height = UIScreen.main.bounds.size.height
//
//        self.remoteVideoView.frame = remoteVideoFrame
//
        var localVideoFrame = AVMakeRect(aspectRatio: localAspectRatio, insideRect: self.localVideoContainerView.bounds);
        localVideoFrame.origin.x = -40
        localVideoFrame.origin.y = 0
        localVideoFrame.size.width = 140
        localVideoFrame.size.height = 100

        self.localVideoView.frame = localVideoFrame
        
        let remoteVideoFrame = AVMakeRect(aspectRatio: remoteAspectRatio, insideRect: self.remoteVideoContainerView.bounds)
        self.remoteVideoView.frame = remoteVideoFrame

    }
}
