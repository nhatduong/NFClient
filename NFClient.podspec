Pod::Spec.new do |s|
  s.ios.deployment_target = '9.0'
  s.name = "NFClient"
  s.summary = "NFClient is network manager"
  s.requires_arc = true
  s.static_framework = true
  s.version = "1.2.41"
  s.platform     = :ios, "9.0"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "NhatNguyen" => "nhatbg89@gmail.com" }
  s.homepage = "https://github.com/nhatduong/NFClient"
  s.source = { :git => "https://github.com/nhatduong/NFClient.git", :tag => "#{s.version}"}
  s.framework = "UIKit", "CFNetwork", "CoreGraphics", "GLKit", "OpenGLES", "QuartzCore", "Security"
  s.dependency 'SwiftyJSON', '~> 5.0.0'
  s.dependency 'Alamofire', '~> 4.9.1'
  s.dependency 'libjingle_peerconnection'
  s.dependency 'SocketRocket', '~> 0.5.1'
  s.dependency 'Socket.IO-Client-Swift', '~> 15.2.0'
  s.dependency 'Starscream', '~> 3.1.1'
  s.swift_version = '5.1.3'
  # s.source_files  = "NFClient/**/*.{*}"
  s.resources = "Videocall/**/*.{png,jpeg,jpg,storyboard,xib}", "PeerClient/**/*.{png,jpeg,jpg,storyboard,xib}", "Frameworks/**/*.{framework}"
  # s.exclude_files = "Classes/Exclude"
  # s.source_files = "PeerClient/Peer/*.{swift,h,m}"
  #s.resources = "FRNetwork/**/*.{png,jpeg,jpg,storyboard,xib}"

end