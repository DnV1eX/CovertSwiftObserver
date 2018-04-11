//
//  Observer.swift
//  SwiftObserver
//
//  Created by Alexey Demin on 2018-04-11.
//

import Foundation


class Observer<Parameters> {
    
    class Handler: CustomStringConvertible {
        
        weak var object: AnyObject?
        
        typealias Closure = (AnyObject) -> (Parameters) -> Bool
        let closure: Closure
        
        init(object: AnyObject, closure: @escaping Closure) {
            self.object = object
            self.closure = closure
        }
        
        @discardableResult func now(_ arguments: Parameters) -> Handler {
            if let object = object {
                _ = closure(object)(arguments)
            }
            return self
        }
        
        var description: String {
            return String(describing: object)
        }
    }
    
    private var handlers = [Handler]()
    
    private let queue = DispatchQueue(label: "ObserverQueue", qos: .userInitiated)
    
    
    init(_: Parameters.Type? = nil) { }
    
    
    @discardableResult func perform<T: AnyObject>(_ object: T, _ closure: @escaping (T) -> (Parameters) -> Void) -> Handler {
        
        let handler = Handler(object: object) { object in { arguments in closure(object as! T)(arguments); return true } }
        add(handler: handler)
        return handler
    }
    
    
    @discardableResult func perform(_ object: AnyObject? = nil, _ closure: @escaping (Parameters) -> Void) -> Handler {
        
        let handler = Handler(object: object ?? self) { _ in { arguments in closure(arguments); return true } }
        add(handler: handler)
        return handler
    }
    
    
    @discardableResult func performOnce(_ object: AnyObject? = nil, _ closure: @escaping (Parameters) -> Void) -> Handler {
        
        let handler = Handler(object: object ?? self) { _ in { arguments in closure(arguments); return false } }
        add(handler: handler)
        return handler
    }
    
    
    @discardableResult func performWhile(_ object: AnyObject? = nil, _ closure: @escaping (Parameters) -> Bool) -> Handler {
        
        let handler = Handler(object: object ?? self) { _ in closure }
        add(handler: handler)
        return handler
    }
    
    
    func notify(_ arguments: Parameters) {
        
        var objects = [(Handler, AnyObject)]() // Retain objects
        queue.sync {
            for (index, handler) in handlers.enumerated() {
                if let object = handler.object {
                    objects.append((handler, object))
                } else {
                    handlers.remove(at: index)
                }
            }
        }
        for (handler, object) in objects {
            if !handler.closure(object)(arguments) {
                remove(handler: handler)
            }
        }
    }
    
    
    func add(handler: Handler) {
        
        queue.sync {
            handlers.append(handler)
        }
    }
    
    
    func remove(handler: Handler) {
        
        queue.sync {
            handlers = handlers.filter { $0 !== handler }
        }
    }
    
    
    func remove(_ object: AnyObject) {
        
        queue.sync {
            handlers = handlers.filter { $0.object !== object }
        }
    }
}

extension Observer where Parameters == Void {
    
    func notify() {
        notify(())
    }
}



protocol Updatable: AnyObject { }

private var onUpdateKey = "onUpdate"

extension Updatable {
    
    var onUpdate: Observer<Void> {
        if let onUpdate = objc_getAssociatedObject(self, &onUpdateKey) as? Observer<Void> {
            return onUpdate
        } else {
            let onUpdate = Observer(Void.self)
            objc_setAssociatedObject(self, &onUpdateKey, onUpdate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return onUpdate
        }
    }
}
