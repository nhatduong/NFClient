Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.name = "FRNetwork"
  s.summary = "FRNetwork is network manager"
  s.requires_arc = true
  s.version = "1.0"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "NhatNguyen" => "nhatbg89@gmail.com" }
  s.homepage = "note3"
  s.source = { :git => "https://github.com/nhatduong/NFClient.git", :tag => "#{s.version}"}
  s.framework = "UIKit"
  s.framework = "CoreLocation"
  s.dependency 'SwiftyJSON'
  s.dependency 'Alamofire'
  s.dependency 'libjingle_peerconnection'
  s.dependency 'SocketRocket'
  s.dependency 'Socket.IO-Client-Swift'
  s.source_files = "NFClient/**/*.{swift,h,m}"
  s.resources = "NFClient/**/*.{png,jpeg,jpg,storyboard,xib}"
end