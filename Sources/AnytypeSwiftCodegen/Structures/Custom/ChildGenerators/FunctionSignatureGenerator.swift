import Foundation
import SwiftSyntax

final class FunctionSignatureGenerator {
    
    init() {}
    
    func generate(args: [Argument], returnType: String) -> FunctionSignatureSyntax {
        
        let returnTypeSyntax = SyntaxFactory.makeTypeIdentifier(returnType)
        
        let parameterList = FunctionParametersGenerator().generate(args: args)
        
        let parametersListSyntax = SyntaxFactory.makeFunctionParameterList(parameterList)
        
        let parameterClauseSyntax = SyntaxFactory.makeParameterClause(
            leftParen: SyntaxFactory.makeLeftParenToken(),
            parameterList: parametersListSyntax,
            rightParen: SyntaxFactory.makeRightParenToken()
        )
        
        let returnClauseSyntax = SyntaxFactory.makeReturnClause(
            arrow: SyntaxFactory.makeArrowToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1)),
            returnType: returnTypeSyntax
        )
        
        let functionSignatureSyntax = FunctionSignatureSyntax {
            b in
            b.useInput(parameterClauseSyntax)
            b.useOutput(returnClauseSyntax)
        }
        
        return functionSignatureSyntax
    }
}
