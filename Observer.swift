//
//  Observer.swift
//  SwiftObserver
//
//  Created by Alexey Demin on 2018-04-11.
//

import Foundation


private let hash = NSHashTable<AnyObserver>.weakObjects()


public struct Group: Hashable, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public let objectIdentifier: ObjectIdentifier?
    public let keyPath: AnyKeyPath?
    public let id: String?
    
    public static func by(_ object: AnyObject, _ keyPath: AnyKeyPath, id: String? = nil) -> Group {
        return Group(ObjectIdentifier(object), keyPath, id)
    }
    
    public static func by(_ object: AnyObject, id: String? = nil) -> Group {
        return Group(ObjectIdentifier(object), nil, id)
    }
    
    public static func by(_ keyPath: AnyKeyPath, id: String? = nil) -> Group {
        return Group(nil, keyPath, id)
    }
    
    public init(stringLiteral value: StringLiteralType) {
        self = Group(nil, nil, value)
    }
    
    private init(_ objectIdentifier: ObjectIdentifier?, _ keyPath: AnyKeyPath?, _ id: String?) {
        self.objectIdentifier = objectIdentifier
        self.keyPath = keyPath
        self.id = id
    }
}


public class AnyObserver {
    
    public let group: Group?
    
    public var all: [AnyObserver] {
        if let group = group {
            return hash.allObjects.filter { $0.group == group }
        } else {
            return [self]
        }
    }
    
    fileprivate init(_ group: Group?) {
        self.group = group
        if group != nil {
            hash.add(self)
        }
    }
    
    fileprivate func revoke(_ group: Group) { }
}


public final class Observer<Parameter>: AnyObserver {
    
    public final class Handler {
        
        public typealias Closure = (AnyObject) -> (Parameter) -> Bool
        
        public private(set) weak var object: AnyObject?
        fileprivate let closure: Closure
        public let group: Group?
        
        public init(_ object: AnyObject, group: Group?, _ closure: @escaping Closure) {
            self.object = object
            self.group = group
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
    
    
    public init(_: Parameter.Type? = nil, group: Group? = nil) {
        super.init(group)
    }
    
    
    @discardableResult public func bind<Object: AnyObject>(_ object: Object, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ keyPath: ReferenceWritableKeyPath<Object, Parameter>) -> Handler {
        
        unbind(object, keyPath)
        let handler = Handler(object, group: .by(object, keyPath)) { object in
            { parameter in
                guard till() else { return once() }
                (object as! Object)[keyPath: keyPath] = parameter
                return !once()
            }
        }
        append(handler)
        return handler
    }
    
    
    @discardableResult public func call<Object: AnyObject>(_ object: Object, group: Group? = nil, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ function: @escaping (Object) -> (Parameter) -> Void) -> Handler {
        
        if let group = group { revokeAll(group) }
        let handler = Handler(object, group: group) { object in
            { parameter in
                guard till() else { return once() }
                function(object as! Object)(parameter)
                return !once()
            }
        }
        append(handler)
        return handler
    }
    
    
    @discardableResult public func call<Object: AnyObject>(_ object: Object, group: Group? = nil, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ function: @escaping (Object) -> () -> Void) -> Handler {
        
        if let group = group { revokeAll(group) }
        let handler = Handler(object, group: group) { object in
            { _ in
                guard till() else { return once() }
                function(object as! Object)()
                return !once()
            }
        }
        append(handler)
        return handler
    }
    
    
    @discardableResult public func run(group: Group? = nil, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ closure: @escaping (Parameter) -> Void) -> Handler {
        
        return run(self, group: group, till: till(), once: once(), closure)
    }
    
    @discardableResult public func run(_ object: AnyObject, group: Group? = nil, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ closure: @escaping (Parameter) -> Void) -> Handler {
        
        if let group = group { revokeAll(group) }
        let handler = Handler(object, group: group) { _ in
            { parameter in
                guard till() else { return once() }
                closure(parameter)
                return !once()
            }
        }
        append(handler)
        return handler
    }
    
    @discardableResult public func run<Object: AnyObject>(_ object: Object, group: Group? = nil, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ closure: @escaping (Object, Parameter) -> Void) -> Handler {
        
        if let group = group { revokeAll(group) }
        let handler = Handler(object, group: group) { object in
            { parameter in
                guard till() else { return once() }
                closure(object as! Object, parameter)
                return !once()
            }
        }
        append(handler)
        return handler
    }
    

    @discardableResult public func till(group: Group? = nil, _ closure: @escaping (Parameter) -> Bool) -> Handler {
        
        return till(self, group: group, closure)
    }
    
    @discardableResult public func till(_ object: AnyObject, group: Group? = nil, _ closure: @escaping (Parameter) -> Bool) -> Handler {
        
        if let group = group { revokeAll(group) }
        let handler = Handler(object, group: group) { _ in closure }
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
        
        revokeAll(.by(object, keyPath))
    }
    
    public func revokeAll(_ group: Group) {
        
        all.forEach { $0.revoke(group) }
    }
    
    public override func revoke(_ group: Group) {
        
        queue.sync {
            handlers.removeAll { $0.group == group }
        }
    }

    public func revoke() {
        
        revoke(self)
    }
    
    public func revoke(_ object: AnyObject) {
        
        queue.sync {
            handlers.removeAll { $0.object === object && $0.group == nil }
        }
    }
}


public extension Observer where Parameter == Void {
    
    convenience init(group: Group? = nil) {
        self.init(Void.self, group: group)
    }

    
    @discardableResult func run<Object: AnyObject>(_ object: Object, group: Group? = nil, till: @autoclosure @escaping () -> Bool = true, once: @autoclosure @escaping () -> Bool = false, _ closure: @escaping (Object) -> Void) -> Handler {
        
        return run(object, group: group, till: till(), once: once()) { object, _ in closure(object) }
    }
    
    
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
            let onUpdate = Observer()
            objc_setAssociatedObject(self, &onUpdateKey, onUpdate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return onUpdate
        }
    }
}
