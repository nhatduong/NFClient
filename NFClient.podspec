Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.name = "NFClient"
  s.summary = "NFClient is network manager"
  s.requires_arc = true
  s.version = "1.0"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "NhatNguyen" => "nhatbg89@gmail.com" }
  s.homepage = "note3"
  s.source = { :git => "https://github.com/nhatduong/NFClient.git", :tag => "#{s.version}"}
  s.framework = "UIKit"
  s.framework = "CFNetwork"
  s.framework = "CoreGraphics"
  s.framework = "GLKit"
  s.framework = "OpenGLES"
  s.framework = "QuartzCore"
  s.framework = "Security"
  s.dependency 'SwiftyJSON', '~> 5.0.0'
  s.dependency 'Alamofire', '~> 4.9.1'
  s.dependency 'libjingle_peerconnection', '~> 11177.2.0'
  s.dependency 'SocketRocket', '~> 0.5.1'
  s.dependency 'Socket.IO-Client-Swift', '~> 15.2.0'
  s.dependency 'Socket.IO-Client-Swift', '~> 3.1.1'
  s.source_files = "NFClient/**/*.{swift,h,m}"
  # s.resources = "NFClient/**/*.{png,jpeg,jpg,storyboard,xib}"
end