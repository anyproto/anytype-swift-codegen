import XCTest
@testable import AnytypeSwiftCodegen

final class InitializerGeneratorTests: XCTestCase
{
    private enum Constants {
        static let template = """
        {% for object in objects %}
        Type = {{ object.type }}
        Fields:
        {% for field in object.fields %}
        {{ field.name }},{{field.type}},{{ field.defaultValue }}
        {% endfor %}
        {% endfor %}
        """
    }
    
    func test_empty() throws
    {
        let source = """
            struct Response {
            }
            """

        let expected = """
            
            Type = Response
            Fields:
            
            """

        try runTest(
            source: source,
            expected: expected,
            using: InitializerGenerator(template: Constants.template)
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
            
            Type = Response
            Fields:
            internalError,Error?,
            integerValue,Int,43

            """

        try runTest(
            source: source,
            expected: expected,
            using: InitializerGenerator(template: Constants.template)
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
            
            Type = Foo
            Fields:
            int,Int,
            Type = Foo.Bar
            Fields:
            bool,Bool,
            
            """

        try runTest(
            source: source,
            expected: expected,
            using: InitializerGenerator(template: Constants.template)
        )
    }
}
