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
    var queue: DispatchQueue!

    override func setUp() {
        super.setUp()
        queue = DispatchQueue(label: "test.queue")
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
        let expectation = self.expectation(description: "async test")
        var finished = 0
        let count = 512
        var set1: Set<String>!
        var set2: Set<String>!

        queue.async {
            set1 = self.getSet(count)
            XCTAssertEqual(set1.count, count)
            finished += 1
            if finished == 2 {
                expectation.fulfill()
                XCTAssertTrue(set1.intersection(set2).isEmpty)
            }
        }
        DispatchQueue.main.async {
            set2 = self.getSet(count)
            XCTAssertEqual(set2.count, count)
            finished += 1
            if finished == 2 {
                expectation.fulfill()
                XCTAssertTrue(set1.intersection(set2).isEmpty)
            }
        }

        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPerformance() {
        self.measure() {
            _ = self.flakeGen.nextStringID()
        }
    }

    private func getSet(_ count: Int) -> Set<String> {
        var set = Set<String>()
        for _ in 1...count {
            let value = self.flakeGen.nextStringID()
            set.insert(value)
        }
        return set
    }

}
