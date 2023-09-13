
Pod::Spec.new do |spec|

  spec.name = "TelnyxRTC"
  spec.version = "0.1.10"
  spec.summary = "Enable Telnyx real-time communication services on iOS."
  spec.description = "The Telnyx iOS WebRTC Client SDK provides all the functionality you need to start making voice calls from an iPhone."
  spec.homepage = "https://github.com/team-telnyx/telnyx-webrtc-ios"
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.author = { "Telnyx LLC" => "mobile.app.eng.chapter@telnyx.com" }
  spec.source = { :git => "https://github.com/team-telnyx/telnyx-webrtc-ios.git", :tag => "#{spec.version}" }

  spec.platform = :ios, "10.0"
  spec.swift_version = "5.0"

  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
			       'ENABLE_BITCODE' => 'NO'
                             }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  spec.source_files = "TelnyxRTC", "TelnyxRTC/**/*.{h,m,swift}"
  spec.exclude_files = "TelnyxRTC/Exclude"

  spec.dependency  "Bugsnag", "~> 6.9.1"
  spec.dependency  "Starscream", "~> 4.0.4"
  spec.dependency  "WebRTC-lib", "~> 94.0.0"
end
