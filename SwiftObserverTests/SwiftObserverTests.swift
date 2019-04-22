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
            }
        }
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
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testBasics() {
        let object = Object()
        
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
        void.revoke(id: "Void")
        void.notify()
        XCTAssertEqual(object.count, 5)
        void.revoke(object, id: "Void")
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
        str.till(object) { [unowned object] str in object.state = str; return str.count < 2 }
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
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
