Pod::Spec.new do |s|
  s.name             = 'ASListAdapter'
  s.version          = '1.0.0'
  s.summary          = 'Texture(AsyncDisplayKit) List Adapter'

  s.description      = 'A Reactive ASTableNode & ASCollectionNode List Adapter for building fast and flexible lists.'

  s.homepage         = 'https://github.com/Geektree0101/ASListAdapter'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Geektree0101' => 'h2s1880@gmail.com' }
  s.source           = { :git => 'https://github.com/Geektree0101/ASListAdapter.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'ASListAdapter/Classes/**/*'
  
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'Texture', '2.6'
end
