//
//  PropertyWrappers.swift
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

import Foundation


@propertyWrapper public final class Observed<Parameter> {
    
    public var wrappedValue: Parameter {
        willSet {
            onWillSet.notify((wrappedValue, newValue))
        }
        didSet {
            onDidSet.notify((oldValue, wrappedValue))
        }
    }
    
    public var projectedValue: Observed { self }
    
    public init(wrappedValue: Parameter) {
        self.wrappedValue = wrappedValue
    }
    
    public let onWillSet = Observer((Parameter, Parameter).self)
    public let onDidSet = Observer((Parameter, Parameter).self)
    
    public func willSet(_ closure: @escaping (Parameter, Parameter) -> Void) {
        onWillSet.run(closure)
    }
    
    public func didSet(_ closure: @escaping (Parameter, Parameter) -> Void) {
        onDidSet.run(closure)
    }
}


@propertyWrapper public final class ObservedSetter<Parameter> {
    
    public var wrappedValue: Parameter {
        didSet {
            onSet.notify(wrappedValue)
        }
    }
    
    public var projectedValue: ObservedSetter { self }
    
    public init(wrappedValue: Parameter) {
        self.wrappedValue = wrappedValue
    }
    
    public let onSet = Observer(Parameter.self)
}


@propertyWrapper public final class ObservedUpdate<Parameter: Equatable> {
    
    public var wrappedValue: Parameter {
        didSet {
            if wrappedValue != oldValue {
                onUpdate.notify(wrappedValue)
            }
        }
    }
    
    public var projectedValue: ObservedUpdate { self }
    
    public init(wrappedValue: Parameter) {
        self.wrappedValue = wrappedValue
    }
    
    public let onUpdate = Observer(Parameter.self)
}
