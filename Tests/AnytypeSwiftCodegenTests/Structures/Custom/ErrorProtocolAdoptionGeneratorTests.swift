//
//  ErrorProtocolGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 23.01.2020.
//

import XCTest
@testable import AnytypeSwiftCodegen

final class ErrorProtocolGeneratorTests: XCTestCase
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
    
    func test_basic() throws
    {
        let source = """
            enum Scope {
                struct Request {
                    enum Kind {}
                }
                struct Response {
                    struct Error {
                        enum Code {}
                    }
                }
            }
            
            enum Scope2 {
                struct Request {
                    enum Kind {}
                }
                struct Response {
                    struct Error {
                        enum Code {}
                    }
                }
            }
            """

        let expected = """
            
            Type = Scope.Response.Error
            Fields:
            Type = Scope2.Response.Error
            Fields:
            
            """

        try runTest(
            source: source,
            expected: expected,
            using: ErrorProtocolGenerator(template: Constants.template)
        )
    }
}
