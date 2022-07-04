//
//  PublicInvocationReturningFutureGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 24.01.2020.
//

import XCTest
@testable import AnytypeSwiftCodegen
 
// For better times
//extension AnytypeSwiftCodegen.PublicInvocationReturningFutureGenerator {
//    final class Tests: XCTestCase {
//        typealias Target = PublicInvocationReturningFutureGenerator
//        func test_basic() throws {
//            let source = """
//                struct Invocation {
//                }
//                """
//
//            let expected = """
//                public static func invoke(abc: String, def: Int) -> Future<Response, Error> {
//                .init{promise in promise(self.result(.init(abc: abc, def: def)))}
//                }
//
//                """
//
//            try runTest(
//                source: source,
//                expected: expected,
//                using: PublicInvocationReturningFutureGenerator()
//            )
//        }
//    }
//}

final class PublicInvocationReturningFutureGeneratorTests: XCTestCase
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
            public static func invoke(abc: String, def: Int = 44) -> Future<Response, Error> {
                .init { promise in promise(self.result(.init(abc: abc, def: def))) }
            }

            """

        try runTest(
            source: source,
            expected: expected,
            using: PublicInvocationReturningFutureGenerator().with(arguments: propertiesList)
        )
    }
}
