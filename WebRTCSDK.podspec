
Pod::Spec.new do |spec|

  spec.name         = "WebRTCSDK"
  spec.version      = "0.0.1"
  spec.summary      = "This is the awesome Telnyx iOS WebRTC SDK."
  spec.description  = "This is the awesome Telnyx iOS WebRTC SDK. Enable VoIP to your iOS App."
  spec.homepage     = "https://github.com/team-telnyx/webrtc-ios-sdk"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "Telnyx" => "guillermo@telnyx.com" }
  spec.source       = { :git => "https://github.com/team-telnyx/webrtc-ios-sdk.git", :tag => "#{spec.version}" }

  spec.platform     = :ios, "10.0"
  spec.swift_version = "5.0"

  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
			       'ENABLE_BITCODE' => 'NO'
                             }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  spec.source_files  = "WebRTCSDK", "WebRTCSDK/**/*.{h,m,swift}"
  spec.exclude_files = "WebRTCSDK/Exclude"
  spec.dependency  "Starscream", "~> 4.0.4"
  spec.dependency  "GoogleWebRTC", "~> 1.1.31999"


end
