//
//  PeerConnectionFactory.swift
//  PeerClient
//
//  Created by Akira Murao on 10/22/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection
import AVFoundation

public class PeerConnectionFactory {
    
    public static let sharedInstance = PeerConnectionFactory()
    
    var factory: RTCPeerConnectionFactory
    var videoCaptureDevice : AVCaptureDevice?
    var connectFactory : RTCPeerConnectionFactory? = nil
    var videoSourceData: RTCAVFoundationVideoSource?
    var audioTrackDataCustom: RTCAudioTrack?
    var _videoTrackData: RTCVideoTrack?
    
    init() {
        RTCPeerConnectionFactory.initializeSSL()
        self.factory = RTCPeerConnectionFactory()
    }
    
    deinit {
        RTCPeerConnectionFactory.deinitializeSSL()
    }

    func createPeerConnection(_ options: PeerConnectionOptions, delegate: RTCPeerConnectionDelegate?) -> RTCPeerConnection? {
        print("Creating RTCPeerConnection.")

        /*
         var pc: RTCPeerConnection? = nil
         if connection.options.type == .data {
         let config: RTCConfiguration = RTCConfiguration()
         config.iceServers = iceServers
         pc = self.factory.peerConnection(with: config, constraints: nil, delegate: connection)
         }
         else if connection.options.type == .media {
         let constraints = self.defaultPeerConnectionConstraints()

         /*
         let config: RTCConfiguration = RTCConfiguration()
         config.iceServers = iceServers
         let pc = self.factory.peerConnection(with: config, constraints: nil, delegate: connection)
         */
         pc = self.factory.peerConnection(withICEServers: iceServers, constraints: constraints, delegate: connection)
         }
         */

        let constraints = self.defaultPeerConnectionConstraints(options)
        let pc = self.factory.peerConnection(withICEServers: options.iceServers, constraints: constraints, delegate: delegate)

        /*
         let config: RTCConfiguration = RTCConfiguration()
         config.iceServers = iceServers
         let pc = self.factory.peerConnection(with: config, constraints: constraints, delegate: connection)
         */
        // TODO: something like ...
        //Negotiator.pcs[connection.type][connection.peer][id] = pc;
        
        return pc
    }

    public func createLocalMediaStream(_deviceCameraName: Int) -> MediaStream? {
        
        guard let stream = self.factory.mediaStream(withLabel: "ARDAMS") else {
//            print("return ow day")
            return nil
        }

        if let localVideoTrack = self.createLocalVideoTrack(_deviceCameraName) {
//            print("return ow day22")
            stream.addVideoTrack(localVideoTrack)
        }

        if let localAudioTrack = self.factory.audioTrack(withID: "ARDAMSa0") {
//            print("return ow day33")
            audioTrackDataCustom = localAudioTrack
            stream.addAudioTrack(localAudioTrack)
        }

        return MediaStream(stream)
    }
    
    public func removeAllCallVideo(_deviceCameraName: Int) -> MediaStream? {
        
        guard let stream = self.factory.mediaStream(withLabel: "ARDAMS") else {
//            print("return ow day")
            return nil
        }

        if let localVideoTrack = self.removeLocalVideoTrack(_deviceCameraName) {
//            print("return ow day22")
            stream.removeVideoTrack(localVideoTrack)
        }

        if let localAudioTrack = self.factory.audioTrack(withID: "ARDAMSa0") {
            stream.removeAudioTrack(localAudioTrack)
        }

        return MediaStream(stream)

    }
    
    
    
    public func disableMicrophoneData() -> MediaStream?
    {
        guard let stream = self.factory.mediaStream(withLabel: "ARDAMS") else {
//            print("return ow day")
            return nil
        }
        
        stream.removeAudioTrack(audioTrackDataCustom)
        audioTrackDataCustom?.setEnabled(false)
        stream.addAudioTrack(audioTrackDataCustom)
        
        return MediaStream(stream)
    }
    
    public func enableMicrophoneData() -> MediaStream?
    {
        guard let stream = self.factory.mediaStream(withLabel: "ARDAMS") else {
//            print("return ow day")
            return nil
        }
        
        stream.removeAudioTrack(audioTrackDataCustom)
        audioTrackDataCustom?.setEnabled(true)
        stream.addAudioTrack(audioTrackDataCustom)
        
        return MediaStream(stream)
    }
    
    public func changeCameraData(_ _deviceCameraName: Int) -> MediaStream?
    {
        guard let stream = self.factory.mediaStream(withLabel: "ARDAMS") else {
//            print("return ow day")
            return nil
        }
        
        #if !(targetEnvironment(simulator))
        if let localVideoTrack = self.editLocalVideoTrack(_deviceCameraName , self.videoSourceData!) {
//            print("return ow day22")
            stream.addVideoTrack(localVideoTrack)
        }

        if let localAudioTrack = self.factory.audioTrack(withID: "ARDAMSa0") {
//            print("return ow day33")
            stream.addAudioTrack(localAudioTrack)
        }
        #endif
        
        return MediaStream(stream)
    }
    
    // MARK: Private

    func defaultPeerConnectionConstraints(_ options: PeerConnectionOptions) -> RTCMediaConstraints? {

        if options.connectionType == .data {
            /*
             if !self.supportSctp {
             let optionalConstraints = [RTCPair(key: "RtpDataChannels", value: "true")]
             let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optionalConstraints)
             return constraints
             }
             */
            return nil

        }
        else if options.connectionType == .media {
            let mandatoryConstraints: [RTCPair] = [
                RTCPair(key: "OfferToReceiveAudio", value: "true"),
                RTCPair(key: "OfferToReceiveVideo", value: "true"),
                RTCPair(key: "echoCancellation", value: "false"),
                RTCPair(key: "googEchoCancellation", value: "false")
            ]
            let optionalConstraints: [RTCPair] = [RTCPair(key: "DtlsSrtpKeyAgreement", value: "true"), RTCPair(key: "internalSctpDataChannels", value: "true")]
            let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: optionalConstraints)
            return constraints
        }

        return nil
    }
    
    
    func editLocalVideoTrack(_ _deviceCameraName: Int,_ source: RTCAVFoundationVideoSource) -> RTCVideoTrack? {

        var videoTrack: RTCVideoTrack?

        #if !(targetEnvironment(simulator))
            source.captureSession.beginConfiguration()

            let currentCameraInput:AVCaptureInput = source.captureSession.inputs.first as! AVCaptureInput
            source.captureSession.removeInput(currentCameraInput)

            var newCamera:AVCaptureDevice! = nil

            print("\(_deviceCameraName)")

            if(_deviceCameraName == 1)
            {
                newCamera = cameraWithPosition(position: .back)
            }else{
                newCamera = cameraWithPosition(position: .front)
            }
        
            var err: NSError?
            var newVideoInput: AVCaptureDeviceInput!
            do {
                newVideoInput = try AVCaptureDeviceInput(device: newCamera)
            } catch let err1 as NSError {
                err = err1
                newVideoInput = nil
            }

            if(newVideoInput == nil || err != nil)
            {
                print("Error creating capture device input: \(err!.localizedDescription)")
            }
            else
            {
                source.captureSession.addInput(newVideoInput)
            }

            source.captureSession.sessionPreset = AVCaptureSession.Preset.vga640x480
        
            source.captureSession.commitConfiguration()
            source.captureSession.startRunning()
        
            videoTrack = self.factory.videoTrack(withID: "ARDAMSv0", source: source)
        #endif

        return videoTrack
    }
    
    func createLocalVideoTrack(_ _deviceCameraName: Int) -> RTCVideoTrack? {

        var videoTrack: RTCVideoTrack?
        
        #if !(targetEnvironment(simulator))

            let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            let source = RTCAVFoundationVideoSource(factory: self.factory, constraints: mediaConstraints)
            videoSourceData = source
            videoTrack = self.factory.videoTrack(withID: "ARDAMSv0", source: source)
        #endif
        
        _videoTrackData = videoTrack
        return videoTrack
    }
    
    func removeLocalVideoTrack(_ _deviceCameraName: Int) -> RTCVideoTrack? {

        var videoTrack: RTCVideoTrack?
        
        videoTrack = nil
        return videoTrack
    }
    
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if #available(iOS 10.0, *) {
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
            for device in discoverySession.devices {
                if device.position == position {
                    return device
                }
            }
        } else {
            let _devices = AVCaptureDevice.devices(for: AVMediaType.video)
            for device in _devices {
                if device.position == position {
                    return device
                }
            }
        }
        
        return nil
    }
}
