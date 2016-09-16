
Pod::Spec.new do |s|
  s.name         = "FlakeGen"
  s.version      = "2.0.0"
  s.summary      = "Flake ID Generator"

  s.homepage     = "https://github.com/max-potapov/FlakeGen.swift"
  s.author       = "Maxim V. Potapov"
  s.license      = { :type => "Apache 2.0" }

  s.ios.deployment_target  = "9.0"
  s.osx.deployment_target  = "10.11"
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "2.0"

  s.source       = { :git => "https://github.com/max-potapov/FlakeGen.swift.git", :tag => s.version.to_s }

  s.source_files  = "FlakeGen/*.{h,swift}"
  s.module_map   = "FlakeGen/module.modulemap"
  s.frameworks  = "Foundation"

  s.requires_arc = true
end

