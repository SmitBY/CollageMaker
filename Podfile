# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
platform :ios, '12.0'

target 'CollageMaker' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'SnapKit', '~> 5.0'
  pod 'RxSwift', '~> 6.0'
  pod 'RxCocoa', '~> 6.0'

  # Pods for CollageMaker

  target 'CollageMakerTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'CollageMakerUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      # Подавляем предупреждения о Sendable в RxSwift
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
    end
  end
end
