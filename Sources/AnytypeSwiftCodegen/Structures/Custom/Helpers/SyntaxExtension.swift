import SwiftSyntax

extension Syntax {
    static var blank: Syntax {
        Syntax(SyntaxFactory.makeBlankSourceFile())
    }
}

extension SourceFileSyntax {
    var asSyntax: Syntax {
        Syntax(self)
    }
}

extension SyntaxFactory {
    static func makeSourceFile(_ codeBlocks: [CodeBlockItemSyntax]) -> SourceFileSyntax {
        return makeSourceFile(
            statements: makeCodeBlockItemList(codeBlocks),
            eofToken: makeToken(.eof, presence: .present)
        )
    }
}
