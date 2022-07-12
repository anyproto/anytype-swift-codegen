//
//  ErrorProtocolGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 23.01.2020.
//

import XCTest
@testable import AnytypeSwiftCodegen

final class ErrorProtocolGeneratorTests: XCTestCase
{
    func test_basic() throws
    {
        let source = """
            enum Scope {
                struct Request {
                    enum Kind {}
                }
                struct Response {
                    struct Error {
                        enum Code {}
                    }
                }
            }
            
            enum Scope2 {
                struct Request {
                    enum Kind {}
                }
                struct Response {
                    struct Error {
                        enum Code {}
                    }
                }
            }
            """

        let expected = """
            
            extension Scope.Response.Error: Swift.Error {}
            extension Scope2.Response.Error: Swift.Error {}
            
            """

        try runTest(
            source: source,
            expected: expected,
            using: ErrorProtocolGenerator()
        )
    }
}
