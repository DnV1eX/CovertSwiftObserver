# CovertSwiftObserver
Swift implementation of the [Observer Pattern](https://en.wikipedia.org/wiki/Observer_pattern) taking full advantage of the latest language features to ensure type and thread safty. The library simplifies the syntax of notifications by hiding redundant service objects and automatically manages unsubscription of observers helping to avoid retain cycles which makes [Reactive Programming](https://en.wikipedia.org/wiki/Reactive_programming) in Swift easier than ever.

## Setup
### Swift Package Manager *(preferred)*
Open your application project in Xcode 11 or later, go to menu `File -> Swift Packages -> Add Package Dependency...` and paste the package repository URL `https://github.com/DnV1eX/CovertSwiftObserver.git`.

### [CocoaPods](https://cocoapods.org)
Add the pod to your `Podfile`:
```ruby
pod 'CovertSwiftObserver', '~> 1.0'
```
Or specify the git directly for the guaranteed latest version:
```ruby
pod 'CovertSwiftObserver', :git => 'https://github.com/DnV1eX/CovertSwiftObserver.git'
```

### Copy File
Alternatively, you can manually copy [CovertSwiftObserver.swift](Sources/CovertSwiftObserver/CovertSwiftObserver.swift) into your project *(not recommended)* or playground.

## Overview of Existing Change Propagation Techniques
### Key-Value Observing (KVO)
Cocoa's object keys observing technology.
- Implemented at the Objective-C runtime level so not much to do with pure Swift.

### Notification Center
A once useful class for sending notifications throughout the app.
- Uses a singleton instance;
- Passes parameters in a dynamic typed dictionary.

### Target-Action
A mechanism used by *Controls* to report events.
- Implemented in AppKit / UIKit;
- Only Objective-C *Selectors* are accepted prior to iOS 14.

### Delegation
A template widely used in UIKit based on a weak object reference conforming to a predefined protocol.
- It is necessary to define a protocol for each delegation;
- Not designed to call multiple delegates.

### Closures
Blocks of functionality with convenient syntax.
- Have a risk of creating retain cycles;
- Manual management of multiple closures;
- Using as callbacks can result in the *pyramid of doom*.

### [RxSwift](https://github.com/ReactiveX/RxSwift) / [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift)
Comprehensive implementation of [Functional Reactive Programming (FRP)](https://en.wikipedia.org/wiki/Functional_reactive_programming).
- Introduces a bunch of redundant entities;
- Requires to wrap your data types;
- Complicates the reading of the program logic, especially for non-adepts of the paradigm;
- Overkill in most cases.

### [Combine](https://developer.apple.com/documentation/combine)
Long-awaited native implementation of [FRP](https://en.wikipedia.org/wiki/Functional_reactive_programming) from Apple.
- Only available since iOS 13;
- Powerful enough to also have an entry threshold.

### Others
There are plenty of (functional) reactive programming libraries and frameworks for Swift out there.
Most of them claim to be simple (or even the simplest) and provide excellent multi-page documentation.
But you know what? You don't need any documentation to start using **CovertSwiftObserver**! 😎

## Usage Example
```swift
class Drone {
    @ObservedUpdate var altitude: Double = 0 // Observe value update
}

class Camera {
    func refocus() { print("Camera refocused") }
}

class RemoteController {
    var displayedAltitude: Double = 0 {
        didSet { print("RC displayed altitude \(displayedAltitude)") }
    }
}

let drone = Drone()
let camera = Camera()
let rc = RemoteController()

drone.$altitude.onUpdate.run { print("Drone altitude \($0)") } // Run closure
drone.$altitude.onUpdate.call(camera, Camera.refocus) // Call function
drone.$altitude.onUpdate.bind(rc, \.displayedAltitude) // Bind property

drone.altitude = 10

// Drone altitude 10.0
// Camera refocused
// RC displayed altitude 10.0
```

## TODO:
- [ ] Document advanced usage and source code;
- [ ] Support binding optionals and non-optionals with providing default values;
- [ ] Eliminate crash when binding uninitialized implicitly unwrapped optionals.

## License
Copyright © 2018 DnV1eX. All rights reserved.
Licensed under the Apache License, Version 2.0.
