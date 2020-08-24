Pod::Spec.new do |s|
  s.name             = 'CovertSwiftObserver'
  s.version          = '1.0.0'
  s.summary          = 'Effortless Reactive Programming in Swift'

  s.description      = <<-DESC
Swift implementation of the [Observer Pattern](https://en.wikipedia.org/wiki/Observer_pattern) taking full advantage of the latest language features to ensure type and thread safty. The library simplifies the syntax of notifications by hiding redundant service objects and automatically manages unsubscription of observers helping to avoid retain cycles which makes [Reactive Programming](https://en.wikipedia.org/wiki/Reactive_programming) in Swift easier than ever.
                       DESC

  s.homepage         = 'https://github.com/DnV1eX/CovertSwiftObserver'
  s.license          = 'Apache License, Version 2.0'
  s.author           = { 'Alexey Demin' => 'dnv1ex@yahoo.com' }
  s.source           = { :git => 'https://github.com/DnV1eX/CovertSwiftObserver.git', :tag => s.version.to_s }

  s.swift_version = '5.0'
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.source_files = 'Sources/CovertSwiftObserver/CovertSwiftObserver.swift'
end
