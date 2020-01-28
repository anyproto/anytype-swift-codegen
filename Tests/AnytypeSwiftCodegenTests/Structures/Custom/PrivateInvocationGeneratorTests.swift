//
//  PrivateInvocationGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 23.01.2020.
//

import XCTest
@testable import AnytypeSwiftCodegen
 
final class PrivateInvocationGeneratorTests: XCTestCase
{
    func test_basic() throws
    {
        let source = """
            struct Invocation {
            }
            """

        let expected = """
            private struct Invocation {
            static func invoke(_ data: Data?) -> Data? { Lib.LibAbcDef(data) }
            }

            """

        try runTest(
            source: source,
            expected: expected,
            using: PrivateInvocationGenerator()
        )
    }
}
