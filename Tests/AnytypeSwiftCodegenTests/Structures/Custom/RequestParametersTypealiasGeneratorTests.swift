//
//  RequestParametersTypealiasGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 27.10.2020.
//

import Foundation
import XCTest
@testable import AnytypeSwiftCodegen
 
final class RequestParametersTypealiasGeneratorTests: XCTestCase
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
            public typealias RequestParameters = (abc: String, def: Int)
            """

        try runTest(
            source: source,
            expected: expected,
            using: RequestParametersTypealiasGenerator().with(propertiesList: propertiesList)
        )
    }
}
