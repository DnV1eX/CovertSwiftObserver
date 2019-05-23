//
//  Observer.swift
//  SwiftObserver
//
//  Created by Alexey Demin on 2018-04-11.
//

import Foundation


public final class Observer<Parameter> {
    
    public final class Handler {
        
        public typealias Closure = (AnyObject) -> (Parameter) -> Bool
        
        public private(set) weak var object: AnyObject?
        fileprivate let closure: Closure
        public fileprivate(set) var keyPath: AnyKeyPath?
        public fileprivate(set) var id: String?
        
        fileprivate init(_ object: AnyObject, closure: @escaping Closure) {
            self.object = object
            self.closure = closure
        }
        
        @discardableResult public func now(_ parameter: Parameter) -> Handler {
            if let object = object {
                _ = closure(object)(parameter)
            }
            return self
        }
    }
    
    public private(set) var handlers = [Handler]()
    
    private let queue = DispatchQueue(label: "ObserverQueue", qos: .userInitiated)
    
    
    public init(_: Parameter.Type? = nil) { }
    
    
    @discardableResult public func bind<Object: AnyObject>(_ object: Object, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ keyPath: ReferenceWritableKeyPath<Object, Parameter>) -> Handler {
        
        unbind(object, keyPath)
        let handler = Handler(object) { object in
            { parameter in
                guard till() else { return once() }
                (object as! Object)[keyPath: keyPath] = parameter
                return !once()
            }
        }
        handler.keyPath = keyPath
        append(handler)
        return handler
    }
    
    
    @discardableResult public func call<Object: AnyObject>(_ object: Object, id: String? = nil, solo: Bool = false, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ function: @escaping (Object) -> (Parameter) -> Void) -> Handler {
        
        revoke(object, id, solo)
        let handler = Handler(object) { object in
            { parameter in
                guard till() else { return once() }
                function(object as! Object)(parameter)
                return !once()
            }
        }
        handler.id = id
        append(handler)
        return handler
    }
    
    
    @discardableResult public func call<Object: AnyObject>(_ object: Object, id: String? = nil, solo: Bool = false, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ function: @escaping (Object) -> () -> Void) -> Handler {
        
        revoke(object, id, solo)
        let handler = Handler(object) { object in
            { _ in
                guard till() else { return once() }
                function(object as! Object)()
                return !once()
            }
        }
        handler.id = id
        append(handler)
        return handler
    }
    
    
    @discardableResult public func run(id: String? = nil, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ closure: @escaping (Parameter) -> Void) -> Handler {
        
        return run(self, id: id, till: till(), once: once(), closure)
    }
    
    @discardableResult public func run(_ object: AnyObject, id: String? = nil, solo: Bool = false, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ closure: @escaping (Parameter) -> Void) -> Handler {
        
        revoke(object, id, solo)
        let handler = Handler(object) { _ in
            { parameter in
                guard till() else { return once() }
                closure(parameter)
                return !once()
            }
        }
        handler.id = id
        append(handler)
        return handler
    }
    
    
    @discardableResult public func till(id: String? = nil, _ closure: @escaping (Parameter) -> Bool) -> Handler {
        
        return till(self, id: id, closure)
    }
    
    @discardableResult public func till(_ object: AnyObject, id: String? = nil, solo: Bool = false, _ closure: @escaping (Parameter) -> Bool) -> Handler {
        
        revoke(object, id, solo)
        let handler = Handler(object) { _ in closure }
        handler.id = id
        append(handler)
        return handler
    }
    
    
    public func notify(_ parameter: Parameter) {
        
        var objects = [(Handler, AnyObject)]() // Retain objects
        queue.sync {
            objects = handlers.compactMap { handler in handler.object.map { (handler, $0) } }
            handlers = objects.map { $0.0 }
        }
        for (handler, object) in objects where !handler.closure(object)(parameter) {
            remove(handler)
        }
    }
    
    
    public func append(_ handler: Handler) {
        
        queue.sync {
            handlers.append(handler)
        }
    }
    
    
    public func remove(_ handler: Handler) {
        
        queue.sync {
            handlers.removeAll { $0 === handler }
        }
    }
    
    
    public func unbind<Object: AnyObject>(_ object: Object, _ keyPath: ReferenceWritableKeyPath<Object, Parameter>) {
        
        queue.sync {
            handlers.removeAll { $0.object === object && $0.keyPath == keyPath }
        }
    }
    
    
    public func revoke(id: String) {
        
        queue.sync {
            handlers.removeAll { $0.id == id }
        }
    }

    public func revoke() {
        
        revoke(self)
    }
    
    public func revoke(_ object: AnyObject, id: String? = nil) {
        
        queue.sync {
            handlers.removeAll { $0.object === object && $0.keyPath == nil && $0.id == id }
        }
    }
    
    private func revoke(_ object: AnyObject, _ id: String?, _ solo: Bool) {
        
        if solo {
            if let id = id {
                revoke(id: id)
            } else {
                revoke(object)
            }
        } else if let id = id {
            revoke(object, id: id)
        }
    }
}


public extension Observer where Parameter == Void {
    
    func notify() {
        notify(())
    }
}


public extension Observer.Handler where Parameter == Void {
    
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
