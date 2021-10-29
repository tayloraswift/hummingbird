//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2021-2021 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if compiler(>=5.5) && canImport(_Concurrency)

import Foundation
import Hummingbird
import HummingbirdFoundation
import HummingbirdXCT
import XCTest

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
class HummingbirdAsyncFilesTests: XCTestCase {
    func randomBuffer(size: Int) -> ByteBuffer {
        var data = [UInt8](repeating: 0, count: size)
        data = data.map { _ in UInt8.random(in: 0...255) }
        return ByteBufferAllocator().buffer(bytes: data)
    }

    func testRead() throws {
        let app = HBApplication(testing: .live)
        app.router.get("test.jpg") { request -> HBResponse in
            let fileIO = HBFileIO(application: request.application)
            let body = try await fileIO.loadFile(path: "test.jpg", context: request.context, logger: request.logger)
            return .init(status: .ok, headers: [:], body: body)
        }
        let buffer = self.randomBuffer(size: 320_003)
        let data = Data(buffer: buffer)
        let fileURL = URL(fileURLWithPath: "test.jpg")
        XCTAssertNoThrow(try data.write(to: fileURL))
        defer { XCTAssertNoThrow(try FileManager.default.removeItem(at: fileURL)) }

        try app.XCTStart()
        defer { app.XCTStop() }

        app.XCTExecute(uri: "/test.jpg", method: .GET) { response in
            XCTAssertEqual(response.body, buffer)
        }
    }

    func testWrite() throws {
        let filename = "testWrite.txt"
        let app = HBApplication(testing: .live)
        app.router.put("store") { request -> HTTPResponseStatus in
            let fileIO = HBFileIO(application: request.application)
            try await fileIO.writeFile(
                contents: request.body,
                path: filename,
                context: request.context,
                logger: request.logger
            )
            return .ok
        }

        try app.XCTStart()
        defer { app.XCTStop() }

        let buffer = ByteBufferAllocator().buffer(string: "This is a test")
        app.XCTExecute(uri: "/store", method: .PUT, body: buffer) { response in
            XCTAssertEqual(response.status, .ok)
        }

        let fileURL = URL(fileURLWithPath: filename)
        let data = try Data(contentsOf: fileURL)
        defer { XCTAssertNoThrow(try FileManager.default.removeItem(at: fileURL)) }
        XCTAssertEqual(String(decoding: data, as: Unicode.UTF8.self), "This is a test")
    }
}

#endif // compiler(>=5.5) && canImport(_Concurrency)