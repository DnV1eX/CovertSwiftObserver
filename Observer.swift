//
//  Observer.swift
//  SwiftObserver
//
//  Created by Alexey Demin on 2018-04-11.
//

import Foundation


public class Observer<Parameters> {
    
    public class Handler {
        
        public typealias Closure = (AnyObject) -> (Parameters) -> Bool
        
        fileprivate weak var object: AnyObject?
        fileprivate let closure: Closure
        
        fileprivate init(object: AnyObject, closure: @escaping Closure) {
            self.object = object
            self.closure = closure
        }
        
        @discardableResult public func now(_ arguments: Parameters) -> Handler {
            if let object = object {
                _ = closure(object)(arguments)
            }
            return self
        }
    }
    
    private var handlers = [Handler]()
    
    private let queue = DispatchQueue(label: "ObserverQueue", qos: .userInitiated)
    
    
    public init(_: Parameters.Type? = nil) { }
    
    
    @discardableResult public func perform<T: AnyObject>(_ closure: @escaping (T) -> (Parameters) -> Void, _ object: T) -> Handler {
        
        let handler = Handler(object: object) { object in { arguments in closure(object as! T)(arguments); return true } }
        add(handler: handler)
        return handler
    }
    
    
    @discardableResult public func perform(for object: AnyObject? = nil, _ closure: @escaping (Parameters) -> Void) -> Handler {
        
        let handler = Handler(object: object ?? self) { _ in { arguments in closure(arguments); return true } }
        add(handler: handler)
        return handler
    }
    
    
    @discardableResult public func performOnce(for object: AnyObject? = nil, _ closure: @escaping (Parameters) -> Void) -> Handler {
        
        let handler = Handler(object: object ?? self) { _ in { arguments in closure(arguments); return false } }
        add(handler: handler)
        return handler
    }
    
    
    @discardableResult public func performWhile(for object: AnyObject? = nil, _ closure: @escaping (Parameters) -> Bool) -> Handler {
        
        let handler = Handler(object: object ?? self) { _ in closure }
        add(handler: handler)
        return handler
    }
    
    
    public func notify(_ arguments: Parameters) {
        
        var objects = [(Handler, AnyObject)]() // Retain objects
        queue.sync {
            for (index, handler) in handlers.enumerated().reversed() {
                if let object = handler.object {
                    objects.append((handler, object))
                } else {
                    handlers.remove(at: index)
                }
            }
        }
        for (handler, object) in objects.reversed() {
            if !handler.closure(object)(arguments) {
                remove(handler: handler)
            }
        }
    }
    
    
    private func add(handler: Handler) {
        
        queue.sync {
            handlers.append(handler)
        }
    }
    
    
    public func remove(handler: Handler) {
        
        queue.sync {
            handlers = handlers.filter { $0 !== handler }
        }
    }
    
    
    public func remove(_ object: AnyObject) {
        
        queue.sync {
            handlers = handlers.filter { $0.object !== object }
        }
    }
}


public extension Observer where Parameters == Void {
    
    @discardableResult func perform<T: AnyObject>(_ closure: @escaping (T) -> () -> Void, _ object: T) -> Handler {

        let handler = Handler(object: object) { object in { _ in closure(object as! T)(); return true } }
        add(handler: handler)
        return handler
    }
    
    
    func notify() {
        notify(())
    }
}


public extension Observer.Handler where Parameters == Void {
    
    func now() {
        now(())
    }
}



public protocol Updatable: AnyObject { }

private var onUpdateKey = "onUpdate"

public extension Updatable {
    
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
