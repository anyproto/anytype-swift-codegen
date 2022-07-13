import SwiftSyntax

extension TypeSyntax {
    var asInherited: InheritedTypeSyntax {
        InheritedTypeSyntax { buinder in buinder.useTypeName(self) }
    }
}
