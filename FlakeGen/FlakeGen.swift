//
//  FlakeGen.swift
//  FlakeGen
//
//  Created by Maxim V. Potapov on 07/02/15.
//
//

import Foundation

private struct FlakeGenConstants {
    static let timeBits: UInt32 = 32
    static let machineBits: UInt32 = 24
    static let machineBitMask: UInt32 = (1 << machineBits) - 1
    static let sequenceBits: UInt32 = 8
    static let sequenceBitMask: UInt32 = (1 << sequenceBits) - 1
    static let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    static let base = 62
}

final public class FlakeGen {

    private var machine: UInt32
    private var epoch: UInt32
    private var lastTime: UInt32
    private var sequence: UInt32

    private var queueTag: UnsafeMutablePointer<Void>
    private var queue: dispatch_queue_t

    public init(machineID: UInt32 = 0, epochTime: UInt32 = 0, dispatchQueue: dispatch_queue_t? = nil) {
        queueTag = UnsafeMutablePointer<Void>(unsafeAddressOf("tag"))
        queue = dispatchQueue != nil ? dispatchQueue! : dispatch_get_main_queue()
        dispatch_queue_set_specific(queue, &queue, queueTag, nil)

        machine = machineID & UInt32(FlakeGenConstants.machineBitMask)
        epoch = epochTime
        lastTime = NSDate().secondsSinceReferenceDate()
        sequence = 0
    }

    public func nextStringID() -> String {
        return encode(nextID())
    }

    public func nextID() -> UInt64 {
        var result: UInt64 = 0
        if dispatch_get_specific(&queue) != nil {
            result = next()
        } else {
            dispatch_sync(queue) {
                result = self.next()
            }
        }
        return result
    }

    private func next() -> UInt64 {
        var time = NSDate().secondsSinceReferenceDate()
        if (lastTime < time) {
            lastTime = time
            sequence = 0
        } else {
            sequence = (sequence + 1) & UInt32(FlakeGenConstants.sequenceBitMask)
            if sequence == 0 {
                while(time == lastTime) {
                    usleep(100000)
                    time = NSDate().secondsSinceReferenceDate()
                }
                lastTime = time
            }
        }

        let flake = UInt64(UInt64(time - epoch) << UInt64(FlakeGenConstants.sequenceBits + FlakeGenConstants.machineBits))
            | UInt64(machine << UInt32(FlakeGenConstants.sequenceBits))
            | UInt64(sequence)

        return flake
    }

    private func encode(value: UInt64) -> String {
        var result = ""
        if value == 0 {
            result.insert(FlakeGenConstants.alphabet[0], atIndex: result.startIndex)
        }
        var quotient = Int(value)
        while (quotient > 0) {
            let remainder = quotient % FlakeGenConstants.base
            quotient = quotient / FlakeGenConstants.base
            result.insert(FlakeGenConstants.alphabet[remainder], atIndex: result.startIndex)
        }
        return result
    }

}

extension NSDate {

    func secondsSinceReferenceDate() -> UInt32 {
        return UInt32(self.timeIntervalSinceReferenceDate)
    }

    class func date(year: Int = 1970, month: Int = 1, day: Int = 1) -> NSDate? {
        let dateComponents = NSDateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        return NSCalendar.currentCalendar().dateFromComponents(dateComponents)
    }

}
