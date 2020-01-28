//
//  Protocols.swift
//  
//
//  Created by Dmitry Lobanov on 27.01.2020.
//

import Foundation
import SwiftSyntax

protocol Generator {
    func generate(_ node: SourceFileSyntax) -> Syntax
}

protocol NestableDeclSyntax: DeclSyntax
{
    var identifier: TokenSyntax { get }
}

extension NestableDeclSyntax
{
    /// Full identifier that supports nested structure for making extension,
    /// e.g. `extension Foo.Bar { ... }`.
    var fullIdentifier: TypeSyntax
    {
        let name = self.identifier.withoutTrivia()
        var parent_ = self.parent

        let generate: (NestableDeclSyntax) -> TypeSyntax = {
            SyntaxFactory.makeMemberTypeIdentifier(baseType: $0.fullIdentifier, period: SyntaxFactory.makePeriodToken(), name: name, genericArgumentClause: nil)
        }
        
        // `parent.fullIdentifier + self.identifier` if possible.
        while let parent = parent_ {
            switch parent {
            case let parent as NestableDeclSyntax: return generate(parent)
            default:
                parent_ = parent.parent
            }
        }

        return SyntaxFactory.makeSimpleTypeIdentifier(
            name: self.identifier.withoutTrivia(),
            genericArgumentClause: nil
        )
    }
}

extension StructDeclSyntax: NestableDeclSyntax {}
extension EnumDeclSyntax: NestableDeclSyntax {}
extension ClassDeclSyntax: NestableDeclSyntax {}
