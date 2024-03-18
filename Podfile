# Uncomment the next line to define a global platform for your project
platform :ios, '14.1'

target 'TelnyxWebRTCDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TelnyxWebRTCDemo
  pod 'TelnyxRTC', :path => '.'

end

target 'TelnyxRTC' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TelnyxRTC
  pod 'Bugsnag', '~> 6.9.1'
  pod 'Starscream', '~> 4.0.6'
  pod 'WebRTC-lib', "~> 117.0.0"
  pod 'JanusMessageSDK', '~> 0.7.24'

  target 'TelnyxRTCTests' do
    # Pods for testing
  end

end

#Disable bitecode -> WebRTC pod doesn't have bitcode enabled

post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['ENABLE_BITCODE'] = 'NO'
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.1'
                  config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
               end
          end
   end
end

