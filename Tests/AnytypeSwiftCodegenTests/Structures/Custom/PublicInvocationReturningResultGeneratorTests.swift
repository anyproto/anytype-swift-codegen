//
//  PublicInvocationReturningResultGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 08.02.2021.
//

import XCTest
@testable import AnytypeSwiftCodegen

final class PublicInvocationReturningResultGeneratorTests: XCTestCase
{
    func test_basic() throws
    {
        let propertiesList = [
            Argument(name: "abc", type: "String"),
            Argument(name: "def", type: "Int", defaultValue: "44")
        ]
        let source = """
            struct Invocation {
            }
            """

        let expected = """
            public static func invoke(abc: String, def: Int = 44) -> Result<Response, Error> {
                self.result(.init(abc: abc, def: def))
            }

            """

        try runTest(
            source: source,
            expected: expected,
            using: PublicInvocationReturningResultGenerator().with(arguments: propertiesList)
        )
    }
}
