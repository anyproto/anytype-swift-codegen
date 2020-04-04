//
//  PublicInvocationGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 24.01.2020.
//

import XCTest
@testable import AnytypeSwiftCodegen
 
final class PublicInvocationGeneratorTests: XCTestCase
{
    func test_basic() throws
    {
        let source = """
            struct Invocation {
            }
            """

        let expected = """
            public static func invoke(abc: String, def: Int) -> Future<Response, Error> {
            .init{promise in promise(self.result(.init(abc: abc, def: def)))}
            }

            """

        try runTest(
            source: source,
            expected: expected,
            using: PublicInvocationGenerator()
        )
    }
}
