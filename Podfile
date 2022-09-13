# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

platform :ios, '11.0'

target 'EMediaExample' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for EMediaExample
pod 'Starscream', '~> 4.0.4'
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      # If when compiling your project, "Undefined symbol" occurs, please add the module name which is having the error here
      if ['Starscream'].include? "#{target}"
        target.build_configurations.each do |config|
          config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
        end
      end
    end
  end

end

target 'ShareScreen' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ShareScreen
pod 'Starscream', '~> 4.0.4'

end
