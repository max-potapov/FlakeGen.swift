
Pod::Spec.new do |s|
  s.name         = 'FlakeGen'
  s.version      = '1.1.0'
  s.summary      = 'Flake ID Generator'

  s.homepage     = 'https://github.com/max-potapov/FlakeGen.swift'
  s.author       = 'Maxim V. Potapov'
  s.license      = { :type => 'Apache 2.0' }
  s.platform     = :ios, '8.0'

  s.source       = { :git => 'https://github.com/max-potapov/FlakeGen.swift.git', :tag => s.version.to_s }

  s.source_files  = 'FlakeGen/*.{h,swift}'
  s.frameworks  = 'Foundation'

  s.requires_arc = true
end

