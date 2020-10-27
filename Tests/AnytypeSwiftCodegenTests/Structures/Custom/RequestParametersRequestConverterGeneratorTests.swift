//
//  RequestParametersRequestConverterGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 27.10.2020.
//

import Foundation
import XCTest
@testable import AnytypeSwiftCodegen
 
final class RequestParametersRequestConverterGeneratorTests: XCTestCase
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
            private static func request(_ parameters: RequestParameters) -> Request {
            .init(abc: parameters.abc, def: parameters.def)
            }

            """

        try runTest(
            source: source,
            expected: expected,
            using: RequestParametersRequestConverterGenerator().with(propertiesList: propertiesList)
        )
    }
}
