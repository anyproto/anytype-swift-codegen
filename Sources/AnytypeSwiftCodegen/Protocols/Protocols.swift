import Foundation
import SwiftSyntax

protocol Generator {
    func generate(_ node: SourceFileSyntax) -> Syntax
}

protocol NestableDeclSyntaxProtocol: DeclSyntaxProtocol {
    var identifier: TokenSyntax { get }
}

extension NestableDeclSyntaxProtocol
{
    /// Full identifier that supports nested structure for making extension,
    /// e.g. `extension Foo.Bar { ... }`.
    var fullIdentifier: TypeSyntax
    {
        let name = self.identifier.withoutTrivia()
        var parent_ = self.parent
        let generate: (NestableDeclSyntaxProtocol) -> TypeSyntax = { value in
            .init(SyntaxFactory.makeMemberTypeIdentifier(baseType: value.fullIdentifier, period: SyntaxFactory.makePeriodToken(), name: name, genericArgumentClause: nil))
        }
        
        // `parent.fullIdentifier + self.identifier` if possible.
        while let parent = parent_ {
            if let declarationParent = parent.asProtocol(DeclSyntaxProtocol.self) as? NestableDeclSyntaxProtocol {
                return TypeSyntax(generate(declarationParent))
            }
            parent_ = parent.parent
        }

        return TypeSyntax(SyntaxFactory.makeSimpleTypeIdentifier(
            name: self.identifier.withoutTrivia(),
            genericArgumentClause: nil)
        )
    }
}

extension StructDeclSyntax: NestableDeclSyntaxProtocol {}
extension EnumDeclSyntax: NestableDeclSyntaxProtocol {}
extension ClassDeclSyntax: NestableDeclSyntaxProtocol {}
