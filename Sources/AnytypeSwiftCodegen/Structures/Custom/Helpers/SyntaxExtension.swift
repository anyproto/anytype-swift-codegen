import SwiftSyntax

extension Syntax {
    static var blank: Syntax {
        Syntax(SyntaxFactory.makeBlankSourceFile())
    }
}
