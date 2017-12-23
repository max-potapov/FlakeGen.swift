//
//  FlakeGen.swift
//  FlakeGen
//
//  Created by Maxim V. Potapov on 07/02/15.
//
//

import Foundation

private enum FlakeGenConstants {
    static let timeBits: UInt32 = 32
    static let machineBits: UInt32 = 24
    static let machineBitMask: UInt32 = (1 << machineBits) - 1
    static let sequenceBits: UInt32 = 8
    static let sequenceBitMask: UInt32 = (1 << sequenceBits) - 1
    static let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    static let base: UInt64 = 62
}

final public class FlakeGen: NSObject {

    private var machine: UInt32
    private var epoch: UInt32
    private var lastTime: UInt32
    private var sequence: UInt32

    private let queueKey = DispatchSpecificKey<String>()
    private let queue: DispatchQueue

    public init(machineID: UInt32 = 0, epochTime: UInt32 = 0, dispatchQueue: DispatchQueue = DispatchQueue.main) {
        queue = dispatchQueue
        queue.setSpecific(key: queueKey, value: "queueLabel")

        machine = machineID & UInt32(FlakeGenConstants.machineBitMask)
        epoch = epochTime
        lastTime = Date().secondsSinceReferenceDate()
        sequence = 0
    }

    public func nextStringID() -> String {
        return encode(nextID())
    }

    public func nextID() -> UInt64 {
        var result: UInt64 = 0
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            result = next()
        } else {
            queue.sync {
                result = self.next()
            }
        }
        return result
    }

    private func next() -> UInt64 {
        var time = Date().secondsSinceReferenceDate()
        if lastTime < time {
            lastTime = time
            sequence = 0
        } else {
            sequence = (sequence + 1) & UInt32(FlakeGenConstants.sequenceBitMask)
            if sequence == 0 {
                while time == lastTime {
                    usleep(100000)
                    time = Date().secondsSinceReferenceDate()
                }
                lastTime = time
            }
        }

        let p1 = UInt64(time - epoch)
        let p2 = UInt64(FlakeGenConstants.sequenceBits + FlakeGenConstants.machineBits)
        let p3 = UInt64(machine << UInt32(FlakeGenConstants.sequenceBits))
        let flake = UInt64(p1 << p2) | p3 | UInt64(sequence)

        return flake
    }

    private func encode(_ value: UInt64) -> String {
        var result = ""
        if value == 0 {
            result.insert(FlakeGenConstants.alphabet[0], at: result.startIndex)
        }
        var quotient = value
        while quotient > 0 {
            let remainder = Int(quotient % FlakeGenConstants.base)
            quotient /= FlakeGenConstants.base
            result.insert(FlakeGenConstants.alphabet[remainder], at: result.startIndex)
        }
        return result
    }

}

extension Date {

    fileprivate func secondsSinceReferenceDate() -> UInt32 {
        return UInt32(self.timeIntervalSinceReferenceDate)
    }

    fileprivate static func date(_ year: Int = 1970, month: Int = 1, day: Int = 1) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        return Calendar.current.date(from: dateComponents)
    }

}
