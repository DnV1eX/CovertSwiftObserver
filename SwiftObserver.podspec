Pod::Spec.new do |s|
  s.name             = 'SwiftObserver'
  s.version          = '1.0'
  s.summary          = 'Clear, yet powerful and thread safe native Swift object Observer designed to replace delegation, callbacks, NotificationCenter, KVO and even complicated ReactiveX.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/DnV1eX/SwiftObserver'
  # s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alexey Demin' => 'dnv1ex@ya.ru' }
  s.source           = { :git => 'https://github.com/DnV1eX/SwiftObserver.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Observer.swift'
  
  # s.frameworks = 'UIKit', 'MapKit'
end
