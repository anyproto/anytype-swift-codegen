//
//  MemberwiseConvenientInitializerGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 22.01.2020.
//

//struct Response {
//    typealias Error = Int
//    var internalError: Error = 0
//    var error: Error {
//      get {return 0}
//      set {theError = newValue}
//    }
//    /// Returns true if `error` has been explicitly set.
//    var hasError: Bool {return "" != nil}
//    /// Clears the value of `error`. Subsequent reads from it will return its default value.
//    mutating func clearError() { nil }
//
//    var unknownFields: [String]
//}
//
//extension Response {
//    init(internalError: Error, error: Error) {
//        self.internalError = internalError
//        self.error = error
//    }
//}
import XCTest
@testable import AnytypeSwiftCodegen

final class MemberwiseConvenientInitializerGeneratorTests: XCTestCase
{
    func test_empty() throws
    {
        let source = """
            struct Response {
            }
            """

        let expected = """

            """

        try runTest(
            source: source,
            expected: expected,
            using: MemberwiseConvenientInitializerGenerator()
        )
    }

    func test_basic() throws
    {
        let source = """
            struct Response {
                typealias Error = Int
                var internalError: Error? = 0
                var error: Error {
                  get {return 0}
                  set {theError = newValue}
                }
                var hasError: Bool {return "" != nil}
                mutating func clearError() { nil }

                var unknownFields = [String]()
            }
            """

        let expected = """


            extension Response {
                init(internalError: Error?) {
                    self.internalError = internalError
                }
            }
            """

        try runTest(
            source: source,
            expected: expected,
            using: MemberwiseConvenientInitializerGenerator()
        )
    }

    func test_nestedStruct() throws
    {
        let source = """
            struct Foo {
                let int: Int
                struct Bar {
                    let bool: Bool
                }
            }
            """

        let expected = """


            extension Foo {
                init(int: Int) {
                    self.int = int
                }
            }

            extension Foo.Bar {
                init(bool: Bool) {
                    self.bool = bool
                }
            }
            """

        try runTest(
            source: source,
            expected: expected,
            using: MemberwiseConvenientInitializerGenerator()
        )
    }
}
