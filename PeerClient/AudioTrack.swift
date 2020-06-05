//
//  AudioTrack.swift
//  PeerClient
//
//  Created by NhatNguyen on 1/15/20.
//  Copyright © 2020 PeerClient. All rights reserved.
//

import Foundation
import libjingle_peerconnection

public class AudioTrack {

    private(set) var audioTrack: RTCAudioTrack?
    
    init?(_ audioTrack: RTCAudioTrack?) {
        
        if let track = audioTrack {
            self.audioTrack = track
        }
        else {
            return nil
        }
    }
    
    public func removeAudio() {
         self.audioTrack = nil
    }
    
}
