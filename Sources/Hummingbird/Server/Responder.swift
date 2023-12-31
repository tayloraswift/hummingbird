//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2021-2023 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import ServiceContextModule

/// Protocol for object that produces a response given a request
///
/// This is the core protocol for Hummingbird. It defines an object that can respond to a request.
public protocol Responder<Input, Output, Context>: Sendable {
    associatedtype Input
    associatedtype Output
    associatedtype Context
    /// Return EventLoopFuture that will be fulfilled with response to the request supplied
    @Sendable func respond(to request: Input, context: Context) async throws -> Output
}

/// Responder that calls supplied closure
public struct CallbackResponder<Input, Output, Context>: Responder {
    let callback: @Sendable (Input, Context) async throws -> Output

    public init(callback: @escaping @Sendable (Input, Context) async throws -> Output) {
        self.callback = callback
    }

    public func respond(to request: Input, context: Context) async throws -> Output {
        try await self.callback(request, context)
    }
}

/// Specialisation of Responder where the Input is a HBRequest and the Output is a HBResponse
public typealias HBResponder<Context> = Responder<HBRequest, HBResponse, Context>
public typealias HBCallbackResponder<Context> = CallbackResponder<HBRequest, HBResponse, Context>
