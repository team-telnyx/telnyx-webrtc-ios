# Uncomment the next line to define a global platform for your project
 platform :ios, '10.0'

target 'TelnyxWebRTCDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TelnyxWebRTCDemo
  # pod 'WebRTCSDK', :path => '.'

end

target 'WebRTCSDK' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WebRTCSDK
  pod 'Starscream', '~> 4.0.4'
  pod 'GoogleWebRTC', '~> 1.1.31999'

  target 'WebRTCSDKTests' do
    # Pods for testing
  end

end

#Disable bitecode -> WebRTC pod doesn't have bitcode enabled
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end

