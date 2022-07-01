import XCTest
@testable import AnytypeSwiftCodegen

final class InitializerGeneratorTests: XCTestCase
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
            using: InitializerGenerator(scope: .public)
        )
    }

    func test_basic() throws
    {
        let source = """
            struct Response {
                typealias Error = Int
                var internalError: Error?
                var integerValue: Int = 43
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
                public init(internalError: Error?, integerValue: Int = 43) {
                    self.internalError = internalError
                    self.integerValue = integerValue
                }
            }

            """

        try runTest(
            source: source,
            expected: expected,
            using: InitializerGenerator(scope: .public)
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
            using: InitializerGenerator(scope: .internal)
        )
    }
}
