import Foundation
import SwiftSyntax

struct CallArgument {
    // function parameter
    let parameter: String?
    // context value
    let value: ExprSyntax
}

extension CallArgument {
    init(parameter: String?, value: String) {
        self.parameter = parameter
        self.value = ExprSyntax(
            SyntaxFactory.makeIdentifierExpr(
                identifier: SyntaxFactory.makeIdentifier(value),
                declNameArguments: nil
            )
        )
    }
}

enum FunctionCallGenerator {
    static func generate(methodName: String, args: [CallArgument]) -> FunctionCallExprSyntax {
        
        let calleeSyntax = SyntaxFactory.makeIdentifierExpr(
            identifier: SyntaxFactory.makeIdentifier(""),
            declNameArguments: nil
        )
        
        let invocationSyntax = SyntaxFactory.makeMemberAccessExpr(
            base: .init(calleeSyntax),
            dot: SyntaxFactory.makeIdentifier(""),
            name: SyntaxFactory.makeIdentifier(methodName),
            declNameArguments: nil
        )
        
        let functionCallArgumentList = args.compactMap { arg in
            TupleExprElementSyntax.init { b in
                if let parameter = arg.parameter {
                    b.useLabel(SyntaxFactory.makeIdentifier(parameter))
                    b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                }
                b.useExpression(arg.value)
                if arg.value != args.last?.value {
                    b.useTrailingComma(SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1)))
                }
            }
        }
        
        let functionCallArgumentListSyntax = SyntaxFactory.makeTupleExprElementList(functionCallArgumentList)
        
        let result = SyntaxFactory.makeFunctionCallExpr(
            calledExpression: .init(invocationSyntax),
            leftParen: SyntaxFactory.makeLeftParenToken(),
            argumentList: functionCallArgumentListSyntax,
            rightParen: SyntaxFactory.makeRightParenToken(),
            trailingClosure: nil,
            additionalTrailingClosures: nil
        )
        return result
    }
}
