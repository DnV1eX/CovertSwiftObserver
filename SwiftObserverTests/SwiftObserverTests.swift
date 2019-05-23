//
//  SwiftObserverTests.swift
//  SwiftObserverTests
//
//  Created by Alexey Demin on 2018-04-13.
//

import XCTest
@testable import SwiftObserver


class SwiftObserverTests: XCTestCase {
    
    class Object {
        var count = 0
        var state: Any? {
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
        int.call(object, id: "Int", Object.int)
        int.call(object, id: "Int", Object.int)
        int.notify(5)
        XCTAssertEqual(object.state as? Int, 5)
        XCTAssertEqual(object.count, 5)
        int.revoke(object)
        int.notify(6)
        XCTAssertEqual(object.state as? Int, 6)
        XCTAssertEqual(object.count, 6)
        int.revoke(object, id: "Int")
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
        void.revoke(id: "Void")
        void.revoke(object, id: "Void")
        void.notify()
        XCTAssertEqual(object.count, 2)
        void.revoke(object)
        void.notify()
        XCTAssertEqual(object.count, 2)
        void.call(object, once: true, Object.void)
        void.notify()
        void.notify()
        XCTAssertEqual(object.count, 3)
        void.call(object, id: "Void", Object.void)
        void.call(object, id: "Void", Object.void)
        void.notify()
        XCTAssertEqual(object.count, 4)
        void.revoke()
        void.revoke(object)
        void.revoke(Object(), id: "Void")
        void.notify()
        XCTAssertEqual(object.count, 5)
        void.revoke(object, id: "Void")
        void.notify()
        XCTAssertEqual(object.count, 5)
        void.call(object, id: "Void", Object.void)
        void.revoke(id: "Void")
        void.notify()
        XCTAssertEqual(object.count, 5)

        object.count = 0
        let any = Observer(Any?.self)
        any.bind(object, \.state)
        any.notify("Test")
        XCTAssertEqual(object.state as? String, "Test")
        XCTAssertEqual(object.count, 1)
        any.notify(nil)
        XCTAssertNil(object.state)
        XCTAssertEqual(object.count, 2)
        any.bind(object, \.state)
        any.notify("")
        XCTAssertEqual(object.state as? String, "")
        XCTAssertEqual(object.count, 3)
        any.revoke(object)
        any.notify(42)
        XCTAssertEqual(object.state as? Int, 42)
        XCTAssertEqual(object.count, 4)
        any.unbind(object, \.state)
        any.notify(nil)
        XCTAssertNotNil(object.state)
        XCTAssertEqual(object.count, 4)

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
        str.till(object) { [unowned object = object!] s in object.state = s; return s.count < 2 }
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
        object.onChangeState.call(expectation, till: obj === sot?.object, XCTestExpectation.fulfill)
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
    
}
