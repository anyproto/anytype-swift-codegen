//
//  PublicInvocationWithQueueGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 29.10.2020.
//

import XCTest
@testable import AnytypeSwiftCodegen
//public static func invoke(id: String, size: Anytype_Model_Image.Size, queue: DispatchQueue? = nil) -> Future<Response, Error> {
//   self.invoke(parameters: .init(id: id, size: size), on: queue)
//}
final class PublicInvocationWithQueueGeneratorTests: XCTestCase
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
            public static func invoke(abc: String, def: Int, queue: DispatchQueue? = nil) -> Future<Response, Error> {
            self.invoke(parameters: .init(abc: abc, def: def), on: queue)
            }

            """

        try runTest(
            source: source,
            expected: expected,
            using: PublicInvocationWithQueueGenerator().with(propertiesList: propertiesList)
        )
    }
}
