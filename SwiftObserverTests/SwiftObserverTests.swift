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
        var state: Any?
        func void() {
            state = nil
        }
        func int(i: Int) {
            state = i
        }
        func optStr(s: String?) {
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
    
    func testExample() {
        let object = Object()
        
        let int = Observer(Int.self)
        int.perform(Object.int, object)
        int.notify(1)
        XCTAssertEqual(object.state as? Int, 1)
        
        let void = Observer(Void.self)
        void.perform(Object.void, object)
        void.notify()
        XCTAssertNil(object.state)
        
        let optStr = Observer(String?.self)
        optStr.perform(Object.optStr, object)
        optStr.notify("OK")
        XCTAssertEqual(object.state as? String, "OK")
        optStr.notify(nil)
        XCTAssertNil(object.state)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
