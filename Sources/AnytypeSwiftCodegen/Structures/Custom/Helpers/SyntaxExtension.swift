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

extension TypeSyntax {
    var asInherited: InheritedTypeSyntax {
        InheritedTypeSyntax { buinder in buinder.useTypeName(self) }
    }
}

extension ExtensionDeclSyntax {
    var asCode: CodeBlockItemSyntax {
        CodeBlockItemSyntax { builder in builder.useItem(Syntax(self)) }
    }
}
