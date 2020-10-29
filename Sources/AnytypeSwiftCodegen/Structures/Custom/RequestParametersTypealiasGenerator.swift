//
//  RequestParametersTypealiasGenerator.swift
//  
//
//  Created by Dmitry Lobanov on 27.10.2020.
//

import Foundation
import SwiftSyntax

/*
 public typealias RequestParameters = (id: String, size: Anytype_Model_Image.Size)
 */

class RequestParametersTypealiasGenerator: SyntaxRewriter {
    struct Options {
        var typealiasName = "RequestParameters"
        var simple: Bool = false
        var simpleAliasName = "Request"
    }
    static func convert(_ variables: [StoredPropertiesExtractor.VariableFilter.Variable]) -> [(String, String)] {
        variables.compactMap { entry -> (String, String)? in
            guard let type = entry.typeAnnotationSyntax?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
            let name = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return (name, type)
        }
    }
    
    func with(variables list: [StoredPropertiesExtractor.VariableFilter.Variable]) -> Self {
        self.storedPropertiesList = Self.convert(list)
        return self
    }
    
    func with(propertiesList list: [(String, String)]) -> Self {
        self.storedPropertiesList = list
        return self
    }
    
    var storedPropertiesList: [(String, String)] = []
    var options: Options = .init()
    convenience init(options: Options, variables: [StoredPropertiesExtractor.VariableFilter.Variable]) {
        self.init(options: options)
        self.storedPropertiesList = Self.convert(variables)
    }
    init(options: Options) {
        self.options = options
    }
    override init() {}
    
    enum Part {
        case `typealias`
    }
    enum PartResult {
        case `typealias`(Syntax)
        func raw() -> Syntax {
            switch self {
            case let .typealias(value): return .init(value)
            }
        }
    }
    
    // MARK: Visits
    override func visit(_ node: SourceFileSyntax) -> Syntax {
        self.generate(node)
    }
}

extension RequestParametersTypealiasGenerator: Generator {
    func generate(_ part: Part, options: Options) -> PartResult {
        switch part {
        case .typealias:
            let tupleElementsList =
                self.storedPropertiesList.compactMap { (name, type) in
                TupleTypeElementSyntax.init { b in
                    b.useName(SyntaxFactory.makeIdentifier(name))
                    b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                    b.useType(.init(SyntaxFactory.makeTypeIdentifier(type)))
                    if name != self.storedPropertiesList.last?.0 {
                        b.useTrailingComma(SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1)))
                    }
                }
            }
            
            let tupleTypeElementsListSyntax = SyntaxFactory.makeTupleTypeElementList(tupleElementsList)
            let tupleTypeSyntax = SyntaxFactory.makeTupleType(leftParen: SyntaxFactory.makeLeftParenToken(), elements: tupleTypeElementsListSyntax, rightParen: SyntaxFactory.makeRightParenToken())
            
            let publicKeyword = SyntaxFactory.makePublicKeyword()
            let attributesListSyntax = SyntaxFactory.makeAttributeList([
                .init(publicKeyword.withTrailingTrivia(.spaces(1))),
            ])
            
            let typealiasKeyword = SyntaxFactory.makeTypealiasKeyword().withTrailingTrivia(.spaces(1))
            let typealiasIdentifierName = SyntaxFactory.makeIdentifier(self.options.typealiasName)
            let equalIdentifier = SyntaxFactory.makeEqualToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1))
            
            let typeInitializerSyntaxResult: TypeSyntax
            if options.simple {
                typeInitializerSyntaxResult = SyntaxFactory.makeTypeIdentifier(options.simpleAliasName)
            }
            else {
                typeInitializerSyntaxResult = .init(tupleTypeSyntax)
            }
            
            let typeInitializerClauseSyntax = SyntaxFactory.makeTypeInitializerClause(equal: equalIdentifier, value: typeInitializerSyntaxResult)
                                    
            let typealiasSyntax = SyntaxFactory.makeTypealiasDecl(attributes: attributesListSyntax, modifiers: nil, typealiasKeyword: typealiasKeyword, identifier: typealiasIdentifierName, genericParameterClause: nil, initializer: typeInitializerClauseSyntax, genericWhereClause: nil)
            return .typealias(.init(typealiasSyntax))
        }
    }
    func generate(_ part: Part) -> Syntax {
        self.generate(part, options: self.options).raw()
    }
    func generate(_ node: SourceFileSyntax) -> Syntax {
        guard !self.storedPropertiesList.isEmpty else { return .init(node) }
        let result = self.generate(.typealias, options: self.options).raw()
        return result
    }
}
