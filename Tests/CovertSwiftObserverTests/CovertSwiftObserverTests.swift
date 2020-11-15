//
//  CovertSwiftObserverTests.swift
//  CovertSwiftObserverTests
//
//  Created by Alexey Demin on 2018-04-13.
//

import XCTest
import CovertSwiftObserver


class CovertSwiftObserverTests: XCTestCase {
    
    class Object: Equatable {
        
        static func == (lhs: Object, rhs: Object) -> Bool {
            lhs.count == rhs.count
        }
        
        @ObservedSetter var count = 0
        
        @ObservedUpdate var sub: Object!
        
        @Observed var state: Any! {
            didSet {
                count += 1
                onChangeState.notify(state)
            }
        }
        let onChangeState = Observer(Any?.self)
        
        func void() {
            state = nil
        }
        func int(i: Int) {
            state = i
        }
        func str(s: String) {
            state = s
        }
        func opt(s: Any?) {
            state = s
        }
    }
    
    var object: Object!

    
    override func setUp() {
        super.setUp()
        object = Object()
    }
    
    override func tearDown() {
        object = nil
        super.tearDown()
    }
    
    
    func testBasics() {
        
        let int = Observer(Int.self)
        int.call(object, Object.int)
        int.notify(1)
        XCTAssertEqual(object.state as? Int, 1)
        XCTAssertEqual(object.count, 1)
        int.notify(2)
        XCTAssertEqual(object.state as? Int, 2)
        XCTAssertEqual(object.count, 2)
        int.call(object, Object.int)
        int.notify(3)
        XCTAssertEqual(object.state as? Int, 3)
        XCTAssertEqual(object.count, 4)
        int.revoke(object)
        int.notify(4)
        XCTAssertEqual(object.state as? Int, 3)
        XCTAssertEqual(object.count, 4)
        int.call(object, group: "Int", Object.int)
        int.call(object, group: "Int", Object.int)
        int.notify(5)
        XCTAssertEqual(object.state as? Int, 5)
        XCTAssertEqual(object.count, 5)
        int.revoke(object)
        int.notify(6)
        XCTAssertEqual(object.state as? Int, 6)
        XCTAssertEqual(object.count, 6)
        int.revoke("Int")
        int.notify(7)
        XCTAssertEqual(object.state as? Int, 6)
        XCTAssertEqual(object.count, 6)

        object.count = 0
        let void = Observer(Void.self)
        void.call(object, Object.void)
        void.notify()
        XCTAssertNil(object.state)
        XCTAssertEqual(object.count, 1)
        void.revoke()
        void.revoke("Void")
        void.notify()
        XCTAssertEqual(object.count, 2)
        void.revoke(object)
        void.notify()
        XCTAssertEqual(object.count, 2)
        void.call(object, Object.void).once()
        void.notify()
        void.notify()
        XCTAssertEqual(object.count, 3)
        void.call(object, group: "Void", Object.void)
        void.call(object, group: "Void", Object.void)
        void.notify()
        XCTAssertEqual(object.count, 4)
        void.revoke()
        void.revoke(object)
        void.revoke(Object())
        void.revoke("void")
        void.notify()
        XCTAssertEqual(object.count, 5)
        void.revoke("Void")
        void.notify()
        XCTAssertEqual(object.count, 5)
        void.call(object, group: "Void", Object.void)
        void.revoke("Void")
        void.notify()
        XCTAssertEqual(object.count, 5)
        void.run(object) { $0.count = 0 }
        void.notify()
        XCTAssertEqual(object.count, 0)
        void.revoke(object)

        object.count = 0
        let optAny = Observer(Any?.self)
        optAny.bind(object, \.state)
        optAny.notify("Test")
        XCTAssertEqual(object.state as? String, "Test")
        XCTAssertEqual(object.count, 1)
        optAny.notify(nil)
        XCTAssertNil(object.state)
        XCTAssertEqual(object.count, 2)
        optAny.bind(object, \.state)
        optAny.notify("")
        XCTAssertEqual(object.state as? String, "")
        XCTAssertEqual(object.count, 3)
        optAny.revoke(object)
        optAny.notify(42)
        XCTAssertEqual(object.state as? Int, 42)
        XCTAssertEqual(object.count, 4)
        optAny.unbind(object, \.state)
        optAny.notify(nil)
        XCTAssertNotNil(object.state)
        XCTAssertEqual(object.count, 4)

        object.state = nil
        object.count = 0
        let any = Observer(Any.self)
        any.run(object) { $0.state = $1 }.now("T")//bind(object, \.state).now("T")
        XCTAssertEqual(object.state as? String, "T")
        XCTAssertEqual(object.count, 1)

        object.count = 0
        let str = Observer(String.self)
        str.call(object, Object.str)
        str.notify("OK")
        XCTAssertEqual(object.state as? String, "OK")
        XCTAssertEqual(object.count, 1)
        str.notify("")
        XCTAssertEqual(object.state as? String, "")
        XCTAssertEqual(object.count, 2)
        str.call(object, Object.void)
        str.notify("Void")
        XCTAssertNil(object.state)
        XCTAssertEqual(object.count, 4)
        str.revoke(object)
        str.notify("")
        XCTAssertNil(object.state)
        XCTAssertEqual(object.count, 4)
        str.run { [weak object] in object?.state = $0 }
        str.notify("")
        XCTAssertEqual(object.state as? String, "")
        XCTAssertEqual(object.count, 5)
        str.revoke()
        str.notify("Revoke")
        XCTAssertEqual(object.state as? String, "")
        XCTAssertEqual(object.count, 5)
        str.run(object) { $0.state = $1 }.until { $0.count < 3 }
        str.notify("A")
        XCTAssertEqual(object.state as? String, "A")
        XCTAssertEqual(object.count, 6)
        str.notify("AB")
        XCTAssertEqual(object.state as? String, "AB")
        XCTAssertEqual(object.count, 7)
        str.notify("ABC")
        XCTAssertEqual(object.state as? String, "AB")
        XCTAssertEqual(object.count, 7)

        object.count = 0
        let tuple = Observer((String, String).self)
        var obj: Object! = Object()
        tuple.run(obj) { [weak object] a, b in object?.state = a + b }.now(("A", "B"))
        XCTAssertEqual(object.state as? String, "AB")
        XCTAssertEqual(object.count, 1)
        tuple.notify(("C", "D"))
        XCTAssertEqual(object.state as? String, "CD")
        XCTAssertEqual(object.count, 2)
        obj = nil
        tuple.notify(("E", "F"))
        XCTAssertEqual(object.state as? String, "CD")
        XCTAssertEqual(object.count, 2)
    }
    
    
    func testGroups() {
        var v = 0
        
        let o1 = Observer()
        let o2 = Observer()
        let o3 = Observer()
        let o4 = Observer(group: "G")
        let o5 = Observer(group: "G")
        let o6 = Observer(group: "G")
        
        o1.run { v += 1 }
        o2.run(group: "G") { v += 10 }
        o3.run(group: "G") { v += 100 }
        o4.run { v += 1000 }
        o5.run(group: "G") { v += 10000 }
        o6.run(group: "G") { v += 100000 }

        o1.notify()
        XCTAssertEqual(v, 1)
        o2.notify()
        XCTAssertEqual(v, 11)
        o3.notify()
        XCTAssertEqual(v, 111)
        o4.notify()
        XCTAssertEqual(v, 1111)
        o5.notify()
        XCTAssertEqual(v, 1111)
        o6.notify()
        XCTAssertEqual(v, 101111)

        o1.run { v += 2 }
        o2.run { v += 20 }
        o3.run(group: "G") { v += 200 }
        o4.run { v += 2000 }
        o5.run { v += 20000 }
        o6.run(group: "G") { v += 200000 }
        
        o1.notify()
        XCTAssertEqual(v, 101114)
        o2.notify()
        XCTAssertEqual(v, 101144)
        o3.notify()
        XCTAssertEqual(v, 101344)
        o4.notify()
        XCTAssertEqual(v, 104344)
        o5.notify()
        XCTAssertEqual(v, 124344)
        o6.notify()
        XCTAssertEqual(v, 324344)
    }
    
    
    func testRetention() {
        
        weak var obj = object
        ;{
            unowned let object = self.object!
            object.onChangeState.run { _ in _ = object }
        }()
        object = nil
        XCTAssertNil(obj)
        
        let expectation = self.expectation(description: "Retention")
        expectation.expectedFulfillmentCount = 2
        object = Object()
        let object = self.object!
        obj = object
        weak var sot = self
        object.onChangeState.call(expectation, XCTestExpectation.fulfill).until { obj === sot?.object }
        object.state = 1
        object.state = 2
        self.object = Object()
        object.state = 3
        self.object = object
        object.state = 4
        wait(for: [expectation], timeout: 1)
    }
    
    
    func testPerformance() {
        
        let observer = Observer(Void.self)
        measure {
            let expectation = self.expectation(description: "Performance")
            expectation.expectedFulfillmentCount = 1000
            for _ in 0..<expectation.expectedFulfillmentCount {
                observer.call(object, Object.void)
            }
            object.onChangeState.call(expectation, XCTestExpectation.fulfill)
            observer.notify()
            observer.revoke(object)
            wait(for: [expectation], timeout: 1)
        }
    }
    
    
    func testWrappers() {
        
        var count = 0
        var state1: String?, state2: String?, oldValue: String?, newValue: String?
        object.$count.onSet.run { count = $0 }
        object.$state.willSet { state1 = $0 as? String; newValue = $1 as? String }
        object.$state.didSet { state2 = $1 as? String; oldValue = $0 as? String }
        object.state = "test"//str(s: "test")
        XCTAssertEqual(count, 1)
        XCTAssertEqual(state1, nil)
        XCTAssertEqual(state2, "test")
        XCTAssertEqual(newValue, "test")
        XCTAssertEqual(oldValue, nil)
        
        let o1 = Object(), o2 = Object(), o3 = Object()
        var o: Object?
        o1.count = 1
        XCTAssertNotEqual(o1, o2)
        XCTAssertEqual(o2, o3)
        object.$sub.onUpdate.run { o = $0 }
        object.sub = o1
        XCTAssert(o === o1)
        object.sub = o2
        XCTAssert(o === o2)
        object.sub = o3
        XCTAssert(o === o2)
    }
    
    
    func testQueue() {
        
        let expectation = XCTestExpectation(description: "Queue")
        let observer = Observer()
        let handler = observer.run { XCTAssert(Thread.isMainThread); expectation.fulfill() }.on(.main).now()
        DispatchQueue.global().async { XCTAssertFalse(Thread.isMainThread); observer.notify() }
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(handler.count, 2)
    }
    
    
    func testRemoval() {
        
        let o1 = Observer()
        let o2 = Observer(group: "1")
        let o3 = Observer(group: "2")
        let o4 = Observer(group: "2")
        let h1 = o1.run({ })
        XCTAssertEqual(o1.handlers.count, 1)
        o2.append(h1)
        XCTAssertEqual(o2.handlers.count, 1)
        o3.append(h1)
        XCTAssertEqual(o3.handlers.count, 1)
        o4.append(h1)
        XCTAssertEqual(o4.handlers.count, 1)
        h1.remove()
        XCTAssertEqual(o1.handlers.count, 0)
        XCTAssertEqual(o2.handlers.count, 0)
        XCTAssertEqual(o3.handlers.count, 0)
        XCTAssertEqual(o4.handlers.count, 0)
        
        o1.run({ })
        o1.run({ })
        XCTAssertEqual(o1.handlers.count, 2)
        o1.revoke()
        XCTAssertEqual(o1.handlers.count, 0)
        o1.run(group: "A", { })
        o1.run(group: "A", { })
        XCTAssertEqual(o1.handlers.count, 1)
        o1.run(group: "B", { })
        o1.run(group: "B", { })
        o2.run(group: "B", { })
        o2.run(group: "B", { })
        o3.run(group: "B", { })
        o3.run(group: "B", { })
        o4.run(group: "B", { })
        o4.run(group: "B", { })
        XCTAssertEqual(o1.handlers.count, 2)
        XCTAssertEqual(o2.handlers.count, 1)
        XCTAssertEqual(o3.handlers.count, 0)
        XCTAssertEqual(o4.handlers.count, 1)
    }
    
    
    func testControl() {
        
        #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
        weak var button: UIButton?
        var b: UIButton? = UIButton()
        b?.onEvent(.touchDown).run { _ in }
        XCTAssertEqual(b?.actions(forTarget: b, forControlEvent: .touchDown), ["onEvent1WithSender:forEvent:"])
        XCTAssertNil(b?.actions(forTarget: b, forControlEvent: .touchUpInside))
        button = b
        b = nil
        XCTAssertNil(button)
        #endif
    }
}
