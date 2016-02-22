Pod::Spec.new do |s|
  s.name                  = "ACECoreDataManager"
  s.version               = "0.1.9"
  s.summary               = "Core data manager."
  s.homepage              = "https://github.com/acerbetti/ACECoreDataManager"
  s.license               = { :type => "MIT", :file => "LICENSE" }
  s.author                = { "Stefano Acerbetti" => "sacerbetti@gmail.com" }
  s.ios.deployment_target = "5.0"
  s.osx.deployment_target = "10.7"
  s.source                = { :git => "https://github.com/acerbetti/ACECoreDataManager.git", :tag => s.version.to_s }
  s.source_files          = "Classes", "ACECoreDataManager/*.{h,m}"
  s.framework             = "CoreData"
  s.requires_arc          = true
end
