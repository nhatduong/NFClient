

import Foundation

var _peerId: String = ""
extension VideoViewController: PeerDelegate {
    
    // MARK: PeerPeerDelegate

    func peer(_ peer: Peer, didOpen peerId: String?) {
        _peerId = peerId!
//        print("peer didOpen peerId: \(peerId ?? "")")
    }

    public func peer(_ peer: Peer, didClose peerId: String?) {
//        print("peer didClose peerId: \(peerId ?? "")")

    }

    func peer(_ peer: Peer, didReceiveError error: Error?) {
        // TODO: what to do?
    }

    func peer(_ peer: Peer, didReceiveConnection connection: PeerConnection, callMetadata: Any) {
        print("12313123====");
        self.answer(connection: connection, callMetadata: callMetadata)
        
    }

    func peer(_ peer: Peer, didCloseConnection connection: PeerConnection) {
        print("Stop tại đây")
        appVar.isAnsewerCall = false
        //endCalling()
        appVar._connectPeerServer = false
        print("Cuộc gọi đã kết thúc")
//        print("peer didCloseConnection \(String(describing: connection))")
    }

    func peer(_ peer: Peer, didReceiveRemoteStream stream: MediaStream) {
        print("peer didReceiveRemoteStream \(String(describing: stream))")

        self.setupRemoteMediaStream(stream)
        
    }

    func peer(_ peer: Peer, didReceiveData data: Data) {

        print("peer didReceive data")
        
//        self.particleViewController?.draw(data)
    }

}
