//
//  StoredPropertiesExtractorTests.swift
//  
//
//  Created by Dmitry Lobanov on 05.05.2020.
//

import Foundation
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

final class StoredPropertiesExtractorTests: XCTestCase
{
    func test_basic() throws
    {
        let source = """
            struct Person {
                var name: String
                var surname: String
                private var id: String
                fileprivate var contactInfo: String
            }
            """

        let expected = source

        try runTest(
            source: source,
            expected: expected,
            using: StoredPropertiesExtractor()
        )
    }
}
