
import Foundation
import NFClient

class CallInfo {

    var callingPeerId: String?
    var incomingConnection: PeerConnection?

    var destPeerId: String? {
        get {
            if let peerId = self.callingPeerId {
                return peerId
            }
            else if let connection = self.incomingConnection {
                return connection.peerId
            }

            // this should not happen
            return nil
        }
    }

    init(peerConnection: PeerConnection) {
        self.incomingConnection = peerConnection
    }

    init(peerId: String) {
        self.callingPeerId = peerId
    }
}
