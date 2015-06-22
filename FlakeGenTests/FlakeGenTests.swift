//
//  FlakeGenTests.swift
//  FlakeGenTests
//
//  Created by Maxim V. Potapov on 07/02/15.
//
//

import Foundation
import XCTest
import FlakeGen

class FlakeGenTests: XCTestCase {

    var flakeGen: FlakeGen!
    var queue: dispatch_queue_t!

    override func setUp() {
        super.setUp()
        queue = dispatch_queue_create("test.queue", DISPATCH_QUEUE_SERIAL)
        flakeGen = FlakeGen(machineID:0xFACE, dispatchQueue:queue)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testStringID() {
        XCTAssertEqual(11, flakeGen.nextStringID().characters.count)
    }

    func testLexicalCompare() {
        let first = flakeGen.nextStringID()
        let second = flakeGen.nextStringID()
        XCTAssertLessThan(first, second)
    }

    func testForUniqueness() {
        let expectation = expectationWithDescription("async test")
        var finished = 0
        let count = 512
        var set1: Set<String>!
        var set2: Set<String>!

        dispatch_async(queue) { [weak expectation] in
            set1 = self.getSet(count)
            XCTAssertEqual(set1.count, count)
            ++finished
            if finished == 2 {
                if let expectation = expectation {
                    expectation.fulfill()
                    XCTAssertTrue(set1.intersect(set2).isEmpty)
                }
            }
        }
        dispatch_async(dispatch_get_main_queue()) { [weak expectation] in
            set2 = self.getSet(count)
            XCTAssertEqual(set2.count, count)
            ++finished
            if finished == 2 {
                if let expectation = expectation {
                    expectation.fulfill()
                    XCTAssertTrue(set1.intersect(set2).isEmpty)
                }
            }
        }

        waitForExpectationsWithTimeout(10) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPerformance() {
        self.measureBlock() {
            self.flakeGen.nextStringID()
        }
    }

    private func getSet(count: Int) -> Set<String> {
        var set = Set<String>()
        for _ in 1...count {
            let value = self.flakeGen.nextStringID()
            set.insert(value)
        }
        return set
    }

}
