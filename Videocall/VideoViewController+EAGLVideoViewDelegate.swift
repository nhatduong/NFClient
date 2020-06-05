
import Foundation
import UIKit

extension VideoViewController: EAGLVideoViewDelegate {

    // MARK: EAGLVideoViewDelegate

    func videoView(videoView: EAGLVideoView!, didChangeVideoSize size: CGSize) {

        if videoView == self.localVideoView {
            self.localVideoSize = size
        }
        else if videoView == self.remoteVideoView {
            self.remoteVideoSize = size
        }
        else {
            //NSParameterAssert(false) // TODO:
        }
        
        self.updateVideoViewLayout()
    }
}
