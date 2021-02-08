//
//  PublicInvocationReturningResultGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 08.02.2021.
//

import XCTest
@testable import AnytypeSwiftCodegen

//public static func invoke(id: String, size: Anytype_Model_Image.Size) -> Result<Response, Error> {
//self.result(.init(id: id, size: size))
//}

final class PublicInvocationReturningResultGeneratorTests: XCTestCase
{
    func test_basic() throws
    {
        let propertiesList: [(String, String)] = [
            ("abc", "String"),
            ("def", "Int")
        ]
        let source = """
            struct Invocation {
            }
            """

        let expected = """
            public static func invoke(abc: String, def: Int) -> Result<Response, Error> {
            self.result(.init(abc: abc, def: def))
            }

            """

        try runTest(
            source: source,
            expected: expected,
            using: PublicInvocationReturningResultGenerator().with(propertiesList: propertiesList)
        )
    }
}
