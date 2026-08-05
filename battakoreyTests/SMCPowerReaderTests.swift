import XCTest
@testable import battakorey

final class SMCPowerReaderTests: XCTestCase {
    func testDecodesLittleEndianFloatPayload() throws {
        let bits = Float(42.25).bitPattern.littleEndian
        let bytes = withUnsafeBytes(of: bits) { Array($0) }

        XCTAssertEqual(try XCTUnwrap(SMCPowerReader.decodeFloat(bytes)), 42.25, accuracy: 0.001)
    }

    func testRejectsInvalidFloatPayloads() {
        XCTAssertNil(SMCPowerReader.decodeFloat([0, 1, 2]))
        XCTAssertNil(SMCPowerReader.decodeFloat([0, 0, 128, 127]))
    }

    func testDecodesTypedIntegerAndFixedPointPayloads() throws {
        XCTAssertEqual(try XCTUnwrap(SMCPowerReader.decode([0x12, 0x34], type: "ui16")), 4_660)
        XCTAssertEqual(try XCTUnwrap(SMCPowerReader.decode([0xff, 0x00], type: "si16")), -256)
        XCTAssertEqual(try XCTUnwrap(SMCPowerReader.decode([0x19, 0x80], type: "sp78")), 25.5)
        XCTAssertEqual(try XCTUnwrap(SMCPowerReader.decode([0xff, 0x80], type: "sp78")), -0.5)
        XCTAssertEqual(try XCTUnwrap(SMCPowerReader.decode([0x00, 0x06], type: "fpe2")), 1.5)
        XCTAssertNil(SMCPowerReader.decode([0, 1], type: "ch8*"))
    }

    func testEncodesFourCharacterSMCKeys() {
        let nonByteKey = String(repeating: "\u{0100}", count: 4)

        XCTAssertEqual(SMCPowerReader.fourCC("PPBR"), 0x50504252)
        XCTAssertNil(SMCPowerReader.fourCC("PPB"))
        XCTAssertNil(SMCPowerReader.fourCC(nonByteKey))
    }
}
