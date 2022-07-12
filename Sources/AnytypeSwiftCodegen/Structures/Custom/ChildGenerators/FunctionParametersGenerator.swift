import Foundation
import SwiftSyntax

/// Example:
/// id: String, size: Anytype_Model_Image.Size
enum FunctionParametersGenerator {
    
    static func generate(args: [Argument]) -> [FunctionParameterSyntax] {
        let parameterList: [FunctionParameterSyntax] = args.compactMap { arg in
            FunctionParameterSyntax { b in
                
                if let internalName = arg.internalName {
                    b.useFirstName(SyntaxFactory.makeIdentifier(arg.name).withTrailingTrivia(.spaces(1)))
                    b.useSecondName(SyntaxFactory.makeIdentifier(internalName))
                } else {
                    b.useFirstName(SyntaxFactory.makeIdentifier(arg.name))
                }
                
                b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                b.useType(SyntaxFactory.makeTypeIdentifier(arg.type))
                
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
