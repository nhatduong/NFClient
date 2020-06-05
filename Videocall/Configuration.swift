

import Foundation
import NFClient

struct Configuration {

    static var peerId: String = "myid0123"
    static var host: String = "peerjs.urlredirect.xyz"
    static var path: String = "/peerjs"
    static var port: Int = 443
    static var key: String = "peerjs"
    static var tokenPeerID: String = "Lam gi co"
    static var wait_audio: String = "https://storage.googleapis.com/lian-data-v2/lian-video-call.mp3"
    static var secure: Bool = true

    static var iceServerOptions: [PeerIceServerOptions]? = nil

    static let herokuPingInterval: TimeInterval = 45.0
}
