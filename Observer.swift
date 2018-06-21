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
    
    
    @discardableResult public func perform<Object: AnyObject>(_ function: @escaping (Object) -> (Parameters) -> Void, of object: Object, exclusively: Bool = false) -> Handler {
        
        if exclusively { stopNotifying(object) }
        let handler = Handler(object: object) { object in { arguments in function(object as! Object)(arguments); return true } }
        add(handler: handler)
        return handler
    }
    
    
    @discardableResult public func perform<Object: AnyObject>(_ function: @escaping (Object) -> () -> Void, of object: Object, exclusively: Bool = false) -> Handler {
        
        if exclusively { stopNotifying(object) }
        let handler = Handler(object: object) { object in { _ in function(object as! Object)(); return true } }
        add(handler: handler)
        return handler
    }
    
    
    @discardableResult public func perform(for object: AnyObject? = nil, exclusively: Bool = false, _ closure: @escaping (Parameters) -> Void) -> Handler {
        
        if exclusively { stopNotifying(object ?? self) }
        let handler = Handler(object: object ?? self) { _ in { arguments in closure(arguments); return true } }
        add(handler: handler)
        return handler
    }
    
    
    @discardableResult public func performOnce(for object: AnyObject? = nil, exclusively: Bool = false, _ closure: @escaping (Parameters) -> Void) -> Handler {
        
        if exclusively { stopNotifying(object ?? self) }
        let handler = Handler(object: object ?? self) { _ in { arguments in closure(arguments); return false } }
        add(handler: handler)
        return handler
    }
    
    
    @discardableResult public func performWhile(for object: AnyObject? = nil, exclusively: Bool = false, _ closure: @escaping (Parameters) -> Bool) -> Handler {
        
        if exclusively { stopNotifying(object ?? self) }
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
    
    
    public func stopNotifying(_ object: AnyObject) {
        
        queue.sync {
            handlers = handlers.filter { $0.object !== object }
        }
    }
}


public extension Observer where Parameters == Void {
    
    func notify() {
        notify(())
    }
}


public extension Observer.Handler where Parameters == Void {
    
    @discardableResult func now() -> Observer.Handler {
        return now(())
    }
    
    
    @discardableResult func now(if condition: Bool) -> Observer.Handler {
        if condition {
            now()
        }
        return self
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
