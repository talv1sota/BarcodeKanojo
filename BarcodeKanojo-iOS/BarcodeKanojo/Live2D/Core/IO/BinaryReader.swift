// BinaryReader.swift — Binary .moc/.bkparts file parser
// Ported from live2d-v2/live2d/core/io/binary_reader.py

import Foundation

final class BinaryReader {
    private var buf: Data
    private var offset: Int = 0
    private var offset8Bit: Int = 0
    private var current8Bit: UInt8 = 0
    private(set) var formatVersion: Int = 0
    private var objects: [Any?] = []

    init(_ data: Data) {
        self.buf = data
    }

    // MARK: - Format Version

    func getFormatVersion() -> Int { formatVersion }

    func setFormatVersion(_ v: Int) {
        formatVersion = v
    }

    // MARK: - Primitive Reads

    func readByte() -> UInt8 {
        checkBits()
        let val = buf[offset]
        offset += 1
        return val
    }

    func readBoolean() -> Bool {
        checkBits()
        let val = buf[offset]
        offset += 1
        return val != 0
    }

    func readBit() -> Bool {
        if offset8Bit == 0 {
            current8Bit = readByte()
        } else if offset8Bit == 8 {
            current8Bit = readByte()
            offset8Bit = 0
        }
        let ret = ((current8Bit >> (7 - offset8Bit)) & 1) == 1
        offset8Bit += 1
        return ret
    }

    func readInt32() -> Int32 {
        checkBits()
        let start = offset
        offset += 4
        return buf.withUnsafeBytes { ptr in
            var val: Int32 = 0
            val |= Int32(ptr[start]) << 24
            val |= Int32(ptr[start + 1]) << 16
            val |= Int32(ptr[start + 2]) << 8
            val |= Int32(ptr[start + 3])
            return val
        }
    }

    func readFloat32() -> Float {
        checkBits()
        let start = offset
        offset += 4
        let bits = buf.withUnsafeBytes { ptr -> UInt32 in
            var val: UInt32 = 0
            val |= UInt32(ptr[start]) << 24
            val |= UInt32(ptr[start + 1]) << 16
            val |= UInt32(ptr[start + 2]) << 8
            val |= UInt32(ptr[start + 3])
            return val
        }
        return Float(bitPattern: bits)
    }

    func readDouble() -> Double {
        checkBits()
        let start = offset
        offset += 8
        let bits = buf.withUnsafeBytes { ptr -> UInt64 in
            var val: UInt64 = 0
            for i in 0..<8 {
                val |= UInt64(ptr[start + i]) << ((7 - i) * 8)
            }
            return val
        }
        return Double(bitPattern: bits)
    }

    func readUShort() -> Int16 {
        checkBits()
        let start = offset
        offset += 2
        return buf.withUnsafeBytes { ptr in
            var val: Int16 = 0
            val |= Int16(ptr[start]) << 8
            val |= Int16(ptr[start + 1])
            return val
        }
    }

    // MARK: - Variable-length number

    func readNumber() -> Int {
        let b1 = Int(readByte())
        if (b1 & 128) == 0 {
            return b1 & 255
        }
        let b2 = Int(readByte())
        if (b2 & 128) == 0 {
            return ((b1 & 127) << 7) | (b2 & 127)
        }
        let b3 = Int(readByte())
        if (b3 & 128) == 0 {
            return ((b1 & 127) << 14) | ((b2 & 127) << 7) | (b3 & 255)
        }
        let b4 = Int(readByte())
        if (b4 & 128) == 0 {
            return ((b1 & 127) << 21) | ((b2 & 127) << 14) | ((b3 & 127) << 7) | (b4 & 255)
        }
        fatalError("number parse error")
    }

    func readType() -> Int {
        return readNumber()
    }

    // MARK: - String

    func readUTF8String() -> String {
        checkBits()
        let length = readType()
        let start = offset
        offset += length
        return String(data: buf[start..<(start + length)], encoding: .utf8) ?? ""
    }

    // MARK: - Array Reads

    func readInt32Array() -> [Int32] {
        checkBits()
        let count = readType()
        var arr = [Int32](repeating: 0, count: count)
        for i in 0..<count {
            arr[i] = readInt32()
        }
        return arr
    }

    func readFloat32Array() -> [Float] {
        checkBits()
        let count = readType()
        var arr = [Float](repeating: 0, count: count)
        for i in 0..<count {
            arr[i] = readFloat32()
        }
        return arr
    }

    func readFloat64Array() -> [Double] {
        checkBits()
        let count = readType()
        var arr = [Double](repeating: 0, count: count)
        for i in 0..<count {
            arr[i] = readDouble()
        }
        return arr
    }

    // MARK: - Object Reads

    func readObject(_ typeHint: Int = -1) -> Any? {
        checkBits()
        var typeNo = typeHint
        if typeNo < 0 {
            typeNo = readType()
        }

        if typeNo == Live2DDEF.OBJECT_REF {
            let idx = Int(readInt32())
            guard idx >= 0 && idx < objects.count else {
                fatalError("Invalid object reference: \(idx)")
            }
            return objects[idx]
        } else {
            let obj = readKnownTypeObject(typeNo)
            objects.append(obj)
            return obj
        }
    }

    private func readKnownTypeObject(_ typeNo: Int) -> Any? {
        if typeNo == 0 {
            return nil
        } else if typeNo == 50 || typeNo == 51 || typeNo == 134 || typeNo == 60 {
            // ID types
            let str = readUTF8String()
            return Live2DId.getID(str)
        } else if typeNo >= 48 {
            // Serializable objects
            let obj = Live2DObjectFactory.create(typeNo)
            obj.read(self)
            return obj
        } else if typeNo == 1 {
            return readUTF8String()
        } else if typeNo == 15 {
            // Generic array
            let count = readType()
            var arr: [Any?] = Array(repeating: nil, count: count)
            for i in 0..<count {
                arr[i] = readObject()
            }
            return arr
        } else if typeNo == 16 || typeNo == 25 {
            return readInt32Array()
        } else if typeNo == 26 {
            return readFloat64Array()
        } else if typeNo == 27 {
            return readFloat32Array()
        }

        fatalError("Unknown type: \(typeNo)")
    }

    // MARK: - Bit Alignment

    private func checkBits() {
        if offset8Bit != 0 {
            offset8Bit = 0
        }
    }
}
