import Foundation
import SwiftSyntax

extension SyntaxRewriter {
    public class Empty: SyntaxRewriter {
        open override func visit(_ syntax: SourceFileSyntax) -> Syntax {
            super.visit(syntax)
        }
    }
}
