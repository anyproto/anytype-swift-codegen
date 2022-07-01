import Foundation
import SwiftSyntax


class RequestParametersTypealiasGenerator: SyntaxRewriter {
    let typealiasName = "RequestParameters"
    let simpleAliasName = "Request"
    
    static func convert(_ variables: [Variable]) -> [(String, String)] {
        variables.compactMap { entry -> (String, String)? in
            let type = entry.typeName
            let name = entry.name
            return (name, type)
        }
    }
    
    func with(variables list: [Variable]) -> Self {
        self.storedPropertiesList = Self.convert(list)
        return self
    }
    
    var storedPropertiesList: [(String, String)] = []
    
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
    func generate(_ part: Part) -> PartResult {
        switch part {
        case .typealias:
            let publicKeyword = SyntaxFactory.makePublicKeyword()
            let attributesListSyntax = SyntaxFactory.makeAttributeList([
                .init(publicKeyword.withTrailingTrivia(.spaces(1))),
            ])
            
            let typealiasKeyword = SyntaxFactory.makeTypealiasKeyword().withTrailingTrivia(.spaces(1))
            let typealiasIdentifierName = SyntaxFactory.makeIdentifier(typealiasName)
            let equalIdentifier = SyntaxFactory.makeEqualToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1))
            
            let typeInitializerSyntaxResult = SyntaxFactory.makeTypeIdentifier(simpleAliasName)
            
            let typeInitializerClauseSyntax = SyntaxFactory.makeTypeInitializerClause(equal: equalIdentifier, value: typeInitializerSyntaxResult)
                                    
            let typealiasSyntax = SyntaxFactory.makeTypealiasDecl(attributes: attributesListSyntax, modifiers: nil, typealiasKeyword: typealiasKeyword, identifier: typealiasIdentifierName, genericParameterClause: nil, initializer: typeInitializerClauseSyntax, genericWhereClause: nil)
            return .typealias(.init(typealiasSyntax))
        }
    }
    func generate(_ part: Part) -> Syntax {
        self.generate(part).raw()
    }
    func generate(_ node: SourceFileSyntax) -> Syntax {
        guard !self.storedPropertiesList.isEmpty else { return .init(node) }
        let result = self.generate(.typealias).raw()
        return result
    }
}
