//
//  MediaStream.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/31.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

public class MediaStream {

    private(set) var stream: RTCMediaStream

    public var videoTracks: [VideoTrack] {
        get {
            var tracks: [VideoTrack] = []
            for track in self.stream.videoTracks {
                if let rtcVideoTrack = track as? RTCVideoTrack, let videoTrack = VideoTrack(rtcVideoTrack) {
                    tracks.append(videoTrack)
                }
            }
            return tracks
        }
    }
    
    public func removeMediaStreamTrack(track: RTCVideoTrack)
    {
        stream.removeVideoTrack(track)
        
    }
    
    public var audioTracks: [AudioTrack] {
        get {
            var tracks: [AudioTrack] = []
            for track in self.stream.audioTracks {
                if let rtcAudioTrack = track as? RTCAudioTrack, let audioTrack = AudioTrack(rtcAudioTrack){
                    tracks.append(audioTrack)
                }
            }
            return tracks
        }
    }

    init?(_ mediaStream: RTCMediaStream?) {

        if let stream = mediaStream {
            self.stream = stream
        }
        else {
            return nil
        }
    }
}
