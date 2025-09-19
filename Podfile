# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'TelnyxWebRTCDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  pod 'Firebase/Core'

  pod 'ReachabilitySwift', '~> 5.2.1'

  # Pods for TelnyxWebRTCDemo
  # Using the framework from the main project instead of as a pod
#   pod 'TelnyxRTC', :path => '.'

end

target 'TelnyxRTC' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TelnyxRTC
  pod 'Starscream', '~> 4.0.8'
  pod 'WebRTC-lib', "~> 139.0.0"

  target 'TelnyxRTCTests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        # Evitar que CocoaPods elimine TelnyxRTC de la app
        if target.name == 'TelnyxRTC'
          config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
          config.build_settings['SKIP_INSTALL'] = 'NO'
        end
      end
    end
  end
end


