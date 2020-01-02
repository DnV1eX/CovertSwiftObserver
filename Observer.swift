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
        fileprivate private(set) var closure: Closure
        public let group: Group?
        public fileprivate(set) var count = 0
        
        
        public init(_ object: AnyObject, group: Group?, _ closure: @escaping Closure) {
            
            self.object = object
            self.group = group
            self.closure = closure
        }
        
        
        @discardableResult public func until(_ condition: @escaping (Parameter, Int) -> Bool) -> Handler {
            
            let closure = self.closure
            self.closure = { [unowned self] object in
                { parameter in
                    return condition(parameter, self.count) ? closure(object)(parameter) : false
                }
            }
            return self
        }
        
        @discardableResult public func until(_ condition: @escaping (Parameter) -> Bool) -> Handler {
            
            return until { parameter, _ in condition(parameter) }
        }
        
        @discardableResult public func until(_ condition: @escaping () -> Bool) -> Handler {
            
            return until { _, _ in condition() }
        }
        
        
        @discardableResult public func once() -> Handler {
            
            return until { _, count in count == 0 }
        }
        
        
        @discardableResult public func now(_ parameter: Parameter) -> Handler {
            
            if let object = object {
                _ = closure(object)(parameter)
                count += 1
            }
            return self
        }
    }
    
    
    public private(set) var handlers = [Handler]()
    
    private let queue = DispatchQueue(label: "ObserverQueue", qos: .userInitiated)
    
    
    public init(_: Parameter.Type? = nil, group: Group? = nil) {
        super.init(group)
    }
    
    
    @discardableResult public func bind<Object: AnyObject>(_ object: Object, _ keyPath: ReferenceWritableKeyPath<Object, Parameter>) -> Handler {
        
        unbind(object, keyPath)
        let handler = Handler(object, group: .by(object, keyPath)) { object in
            { parameter in
                (object as! Object)[keyPath: keyPath] = parameter
                return true
            }
        }
        append(handler)
        return handler
    }
    
    
    @discardableResult public func call<Object: AnyObject>(_ object: Object, group: Group? = nil, _ function: @escaping (Object) -> (Parameter) -> Void) -> Handler {
        
        if let group = group { revokeAll(group) }
        let handler = Handler(object, group: group) { object in
            { parameter in
                function(object as! Object)(parameter)
                return true
            }
        }
        append(handler)
        return handler
    }
    
    @discardableResult public func call<Object: AnyObject>(_ object: Object, group: Group? = nil, _ function: @escaping (Object) -> () -> Void) -> Handler {
        
        return call(object, group: group) { object in { _ in function(object)() } }
    }
    
    
    @discardableResult public func run<Object: AnyObject>(_ object: Object, group: Group? = nil, _ closure: @escaping (Object, Parameter) -> Void) -> Handler {
        
        if let group = group { revokeAll(group) }
        let handler = Handler(object, group: group) { object in
            { parameter in
                closure(object as! Object, parameter)
                return true
            }
        }
        append(handler)
        return handler
    }
    
    @discardableResult public func run(_ object: AnyObject, group: Group? = nil, _ closure: @escaping (Parameter) -> Void) -> Handler {
        
        return run(object, group: group) { _, parameter in closure(parameter) }
    }
 
    @discardableResult public func run(group: Group? = nil, _ closure: @escaping (Parameter) -> Void) -> Handler {
        
        return run(self, group: group) { _, parameter in closure(parameter) }
    }

    @discardableResult public func run(_ object: AnyObject, group: Group? = nil) -> Handler {
        
        return run(object, group: group) { _, _ in }
    }
    
    @discardableResult public func run(group: Group? = nil) -> Handler {
        
        return run(self, group: group) { _, _ in }
    }
    
    
    public func notify(_ parameter: Parameter) {
        
        var objects = [(Handler, AnyObject)]() // Retain objects
        queue.sync {
            objects = handlers.compactMap { handler in handler.object.map { (handler, $0) } }
            handlers = objects.map { $0.0 }
        }
        for (handler, object) in objects {
            if handler.closure(object)(parameter) {
                handler.count += 1
            } else {
                remove(handler)
            }
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

    
    @discardableResult func run<Object: AnyObject>(_ object: Object, group: Group? = nil, _ closure: @escaping (Object) -> Void) -> Handler {
        
        return run(object, group: group) { object, _ in closure(object) }
    }
    
    
    func notify() {
        notify(())
    }
}


public extension Observer.Handler where Parameter == Void {
    
    @discardableResult func until(_ condition: @escaping (Int) -> Bool) -> Observer.Handler {
        
        return until { _, count in condition(count) }
    }
    
    
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



@propertyWrapper public struct Observed<Parameter> {
    
    public var wrappedValue: Parameter {
        willSet {
            onWillSet.notify((wrappedValue, newValue))
        }
        didSet {
            onDidSet.notify((oldValue, wrappedValue))
        }
    }
    
    public var projectedValue: Self { self }
    
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


@propertyWrapper public struct ObservedSetter<Parameter> {
    
    public var wrappedValue: Parameter {
        didSet {
            onSet.notify(wrappedValue)
        }
    }
    
    public var projectedValue: Self { self }
    
    public init(wrappedValue: Parameter) {
        self.wrappedValue = wrappedValue
    }
    
    public let onSet = Observer(Parameter.self)
}


@propertyWrapper public struct ObservedUpdate<Parameter: Equatable> {
    
    public var wrappedValue: Parameter {
        didSet {
            if wrappedValue != oldValue {
                onUpdate.notify(wrappedValue)
            }
        }
    }
    
    public var projectedValue: Self { self }
    
    public init(wrappedValue: Parameter) {
        self.wrappedValue = wrappedValue
    }
    
    public let onUpdate = Observer(Parameter.self)
}
