import Foundation
import SwiftSyntax

enum FunctionDeclGenerator {
    
    static func generate(
        accessLevel: AccessLevel? = nil,
        staticFlag: Bool = false,
        name: String,
        args: [Argument],
        returnType: String,
        body: CodeBlockSyntax
    ) -> FunctionDeclSyntax {
        
        let attributesListSyntax = AttributesListGenerator.generate(accessLevel: accessLevel, staticFlag: staticFlag)
        let functionKeyword = SyntaxFactory.makeFuncKeyword()
        let functionNameSyntax = SyntaxFactory.makeIdentifier(name)
        let functionSignatureSyntax = FunctionSignatureGenerator.generate(args: args, returnType: returnType)
        
        return SyntaxFactory.makeFunctionDecl(
            attributes: attributesListSyntax,
            modifiers: nil,
            funcKeyword: functionKeyword.withTrailingTrivia(.spaces(1)),
            identifier: functionNameSyntax,
            genericParameterClause: nil,
            signature: functionSignatureSyntax,
            genericWhereClause: nil,
            body: body
        )
    }
}
