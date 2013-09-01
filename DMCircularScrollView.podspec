Pod::Spec.new do |s|
  s.name         = 'DMCircularScrollView'
  s.version      = '1.0.0'
  s.summary      = 'Infinite/Circular Scrolling Implementation for UIScrollView.'
  s.homepage     = 'https://github.com/malcommac/DMCircularScrollView'
  s.license      = 'MIT'
  s.author       = { 'Daniele Margutti' => 'http://www.danielemargutti.com' }            
  s.source       = { :git => 'https://github.com/malcommac/DMCircularScrollView.git', :tag => '1.0.0' }
  s.platform     = :ios
  s.ios.deployment_target = '5.0'
  s.source_files = 'Classes', 'DMCircularScrollView/DMCircularScrollView/*.{h,m}'
  s.requires_arc = true
end
