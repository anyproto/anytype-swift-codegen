import Foundation
import SwiftSyntax

class FunctionParametersGenerator {
    
    init() {}
    
    func generate(args: [Argument]) -> [FunctionParameterSyntax] {
        let parameterList: [FunctionParameterSyntax] = args.compactMap { arg in
            FunctionParameterSyntax { b in
                b.useFirstName(SyntaxFactory.makeIdentifier(arg.name))
                b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                b.useType(SyntaxFactory.makeTypeIdentifier(arg.type))
                if arg.name != args.last?.name  {
                    b.useTrailingComma(SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1)))
                }
                
                if let defaultValue = arg.defaultValue {
                    let lastParameterDefaultArgumentSyntax = InitializerClauseSyntax { (b) in
                        b.useEqual(SyntaxFactory.makeEqualToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1)))
                        b.useValue(.init(SyntaxFactory.makeVariableExpr(defaultValue)))
                    }
                    b.useDefaultArgument(lastParameterDefaultArgumentSyntax)
                }
                
                if arg.name != args.last?.name {
                    b.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: [.spaces(1)]))
                }
            }
        }
        return parameterList
    }
}
