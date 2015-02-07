//
//  FlakeGen.swift
//  FlakeGen
//
//  Created by Maxim V. Potapov on 07/02/15.
//
//

import Foundation

private struct FlakeGenConstants {
    static let timeBits = 32
    static let machineBits = 24
    static let machineBitMask = (1 << machineBits) - 1
    static let sequenceBits = 8
    static let sequenceBitMask = (1 << sequenceBits) - 1
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
        let flake = nextID().reverse()
        let encodedFlake = NSData(bytes: flake, length: flake.count).base64EncodedStringWithOptions(nil)
        return encodedFlake.substringToIndex(encodedFlake.endIndex.predecessor())
    }

    public func nextID() -> [Byte] {
        var result: [Byte]?
        if dispatch_get_specific(&queue) != nil {
            result = next()
        } else {
            dispatch_sync(queue) {
                result = self.next()
            }
        }
        return result!
    }

    private func next() -> [Byte] {
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

        let flake = UInt64((time - epoch) << (FlakeGenConstants.sequenceBits + FlakeGenConstants.machineBits))
            | UInt64(machine << UInt32(FlakeGenConstants.sequenceBits))
            | UInt64(sequence)

        return toByteArray(flake)
    }

    private func toByteArray<T>(var value: T) -> [Byte] {
        return withUnsafePointer(&value) {
            Array(UnsafeBufferPointer(start: UnsafePointer<Byte>($0), count: sizeof(T)))
        }
    }

    private func fromByteArray<T>(value: [Byte], _: T.Type) -> T {
        return value.withUnsafeBufferPointer {
            return UnsafePointer<T>($0.baseAddress).memory
        }
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
