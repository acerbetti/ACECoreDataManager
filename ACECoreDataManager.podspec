Pod::Spec.new do |s|
  s.name                  = "ACECoreDataManager"
  s.version               = "0.2.1"
  s.summary               = "Core data manager."
  s.homepage              = "https://github.com/acerbetti/ACECoreDataManager"
  s.license               = { :type => "MIT", :file => "LICENSE" }
  s.author                = { "Stefano Acerbetti" => "sacerbetti@gmail.com" }
  s.source                = { :git => "https://github.com/acerbetti/ACECoreDataManager.git", :tag => s.version.to_s }
  s.framework             = "CoreData"
  s.ios.deployment_target = "5.0"
  s.osx.deployment_target = "10.7"
  s.default_subspecs      = "Core", "UI"
  s.requires_arc          = true

  s.subspec 'Core' do |ss|
    ss.ios.deployment_target = "5.0"
    ss.osx.deployment_target = "10.7"
    ss.source_files          = "Classes", "ACECoreDataManager/*.{h,m}"
    ss.exclude_files         = "ACECoreDataManager/ACECoreDataTableViewController*.{h,m}"
  end

  s.subspec 'UI' do |ss|
    ss.ios.deployment_target = "5.0"
    ss.dependency            "ACECoreDataManager/Core"
    ss.source_files          = "ACECoreDataManager/ACECoreDataTableViewController*.{h,m}"
  end

  s.subspec 'PullToRefresh' do |ss|
    ss.ios.deployment_target = "5.0"
    ss.dependency            "ACECoreDataManager/UI"
    ss.dependency            "SVPullToRefresh", "~> 0.4"
    ss.source_files          = "Classes", "ACECoreDataNetworkTableViewController/*.{h,m}"
  end

end
