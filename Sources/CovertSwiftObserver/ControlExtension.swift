//
//  ControlExtension.swift
//  CovertSwiftObserver
//
//  Created by Alexey Demin on 2020-11-08.
//  Copyright © 2018 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import UIKit


public protocol Control: UIControl { }

public extension Control {
    
    func onEvent(_ event: UIControl.Event) -> Observer<(sender: Self, event: UIEvent?)> {
        
        let selector = Selector(("onEvent\(event.rawValue)WithSender:forEvent:"))
        if let onEvent = objc_getAssociatedObject(self, sel_getName(selector)) as? Observer<(sender: Self, event: UIEvent?)> {
            return onEvent
        } else {
            let onEvent = Observer<(sender: Self, event: UIEvent?)>()
            objc_setAssociatedObject(self, sel_getName(selector), onEvent, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            let block: @convention(block) (AnyObject, UIControl, UIEvent?) -> Void = { ($1 as! Self).onEvent(event).notify(($1 as! Self, $2)) }
            class_addMethod(Self.self, selector, imp_implementationWithBlock(block), "v@:@@")
            addTarget(self, action: selector, for: event)
            return onEvent
        }
    }
}

extension UIControl: Control { }
#endif
