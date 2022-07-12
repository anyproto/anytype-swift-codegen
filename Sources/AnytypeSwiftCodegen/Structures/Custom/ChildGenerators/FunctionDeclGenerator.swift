import Foundation
import SwiftSyntax

/// Example:
/// public static func invoke(id: String, size: Anytype_Model_Image.Size) -> Future<Response, Error> {
///     // body
/// }
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
