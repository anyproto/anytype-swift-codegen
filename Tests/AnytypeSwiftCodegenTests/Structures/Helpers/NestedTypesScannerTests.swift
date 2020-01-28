//
//  NestedTypesScannerTests.swift
//  
//
//  Created by Dmitry Lobanov on 23.01.2020.
//

import XCTest
@testable import AnytypeSwiftCodegen

//enum Scope {
//    struct Request {
//        enum Kind {}
//    }
//    struct Response {
//        struct Error {
//            enum Code {}
//        }
//    }
//}

final class NestedTypesScannerTests: XCTestCase
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
            """

        let expected = source

        try runTest(
            source: source,
            expected: expected,
            using: NestedTypesScanner()
        )
    }
}
