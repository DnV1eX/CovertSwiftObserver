//
//  UpdatableProtocol.swift
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


private var onUpdateKey = "onUpdate"


public protocol Updatable: AnyObject { }

public extension Updatable {
    
    var onUpdate: Observer<Void> {
        
        if let onUpdate = objc_getAssociatedObject(self, &onUpdateKey) as? Observer<Void> {
            return onUpdate
        } else {
            let onUpdate = Observer()
            objc_setAssociatedObject(self, &onUpdateKey, onUpdate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return onUpdate
        }
    }
}
