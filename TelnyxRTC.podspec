
Pod::Spec.new do |spec|

  spec.name = "TelnyxRTC"
  spec.version = "2.0.0"
  spec.summary = "Enable Telnyx real-time communication services on iOS."
  spec.description = "The Telnyx iOS WebRTC Client SDK provides all the functionality you need to start making voice calls from an iPhone."
  spec.homepage = "https://github.com/team-telnyx/telnyx-webrtc-ios"
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.author = { "Telnyx LLC" => "mobile.app.eng.chapter@telnyx.com" }
  spec.source = { :git => "https://github.com/team-telnyx/telnyx-webrtc-ios.git", :tag => "#{spec.version}" }

  spec.platform = :ios, "12.0"
  spec.swift_version = "5.0"

  spec.source_files = "TelnyxRTC", "TelnyxRTC/**/*.{h,m,swift}"
  spec.exclude_files = "TelnyxRTC/Exclude"
  spec.resource_bundles = {"TelnyxRTC" => ["TelnyxRTC/PrivacyInfo.xcprivacy"]}

  spec.dependency  "Starscream", "~> 4.0.8"
  spec.dependency  "WebRTC-lib", "~> 124.0.0"
end
