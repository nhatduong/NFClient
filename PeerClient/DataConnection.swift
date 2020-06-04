//
//  DataConnection.swift
//  PeerClient
//
//  Created by Akira Murao on 10/16/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

public class DataConnection: PeerConnection {

    var dc: RTCDataChannel? {
        didSet {
            self.configureDataChannel()
        }
    }

    var buffer: [String]
    var buffering: Bool
    var bufferSize: Int
    
    var chunkedData: [String]

    var util: Utility
    //var reliable: Reliable?
    
    override init(peerId: String?, delegate: PeerConnectionDelegate?, options: PeerConnectionOptions) {

        self.dc = nil

        // Data channel buffering.
        self.buffer = []
        self.buffering = false
        self.bufferSize = 0

        // For storing large data.
        self.chunkedData = []

        self.util = Utility()

        super.init(peerId: peerId, delegate: delegate, options: options)
    }

    func open(_ completion: @escaping (Result<[String: Any], Error>) -> Void) {

//        print("open (\(self.options.connectionId) <<")

        // if payload does NOT exists, it is considered as originator
        guard self.options.payload.count == 0 else {
//            print("ERROR: options.payload.count > 0")
            completion(.failure(PeerConnectionError.invalidState))
            return
        }

        let factory = PeerConnectionFactory.sharedInstance
        guard let pc = factory.createPeerConnection(self.options, delegate: self) else {
//            print("ERROR: pc is nil")
            completion(.failure(PeerConnectionError.invalidState))
            return
        }
        self.pc = pc

        // moved from negotiator only for data
        guard let dc = negotiator.createDataChannel(pc, options: self.options) else {
//            print("ERROR: dc is nil")
            completion(.failure(PeerConnectionError.creatingDataChannel))
            return
        }
        self.dc = dc

        self.negotiator.startConnection(pc, peerId: self.peerId, options: self.options, completion: completion)

//        print("open (\(self.options.connectionId) >>")
    }

    func answer(_ completion: @escaping (Result<[String: Any], Error>) -> Void) {

//        print("answer (\(self.options.connectionId) <<")

        guard self.options.payload.count > 0 else {
//            print("ERROR: options.payload.count > 0")
            completion(.failure(PeerError.invalidState))
            return
        }
        
        let factory = PeerConnectionFactory.sharedInstance
        guard let pc = factory.createPeerConnection(self.options, delegate: self) else {
//            print("ERROR: pc is nil")
            completion(.failure(PeerError.invalidState))
            return
        }
        self.pc = pc

        self.negotiator.answerConnection(pc, peerId: self.peerId, options: self.options) { [weak self] (result) in
            self?.isOpen = true
            completion(result)
        }
        
//        print("answer (\(self.options.connectionId) >>")
    }
    
    func configureDataChannel() {

        self.dc?.delegate = self
        
    }
    
    // Handles a DataChannel message.
    func handleDataMessage(e: [String: Any]) {

    }
    
    // MARK: data channel utilities

    public func sendData(bytes: [UInt8]) {

        if let dataChannel = self.dc {
            let data = Data(bytes: bytes)
            let buffer = RTCDataBuffer(data: data, isBinary: true)
            dataChannel.sendData(buffer)
        }

    }
}
