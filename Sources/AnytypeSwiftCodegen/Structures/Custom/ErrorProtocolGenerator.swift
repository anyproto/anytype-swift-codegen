import SwiftSyntax

public class ErrorProtocolGenerator: Generator {
    public init() { }
    
    public func generate(_ node: SourceFileSyntax) -> Syntax {
        let statements = NestedTypesScanner().scan(node)
            .flatMap(findAllErrors)
            .map(generate)
        
        return SyntaxFactory.makeSourceFile(statements).asSyntax
    }
    
    // MARK: - Private
    private func generate(_ item: DeclarationNotation) -> CodeBlockItemSyntax {
        let extendedType = item.fullIdentifier
        let extendedTypeSyntax = SyntaxFactory.makeTypeIdentifier(extendedType)
        let inheritanceType = "Swift.Error"
        let inheritanceTypeSyntax = SyntaxFactory.makeTypeIdentifier(inheritanceType)
        let inheritedTypeListSyntax = SyntaxFactory.makeInheritedTypeList(
            [
                .init {b in b.useTypeName(inheritanceTypeSyntax)}
            ]
        )
        let typeInheritanceClauseSyntax = SyntaxFactory
            .makeTypeInheritanceClause(
                colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
                inheritedTypeCollection: inheritedTypeListSyntax
            )
        
        let memberDeclListSyntax = SyntaxFactory.makeMemberDeclList([])
        let memberDeclBlockSyntax = SyntaxFactory.makeMemberDeclBlock(
            leftBrace: SyntaxFactory.makeLeftBraceToken(),
            members: memberDeclListSyntax,
            rightBrace: SyntaxFactory.makeRightBraceToken().withTrailingTrivia(.newlines(1))
        
        )
        let declaration = SyntaxFactory.makeExtensionDecl(
            attributes: nil,
            modifiers: nil,
            extensionKeyword: SyntaxFactory.makeExtensionKeyword().withTrailingTrivia(.spaces(1)),
            extendedType: extendedTypeSyntax,
            inheritanceClause: typeInheritanceClauseSyntax,
            genericWhereClause: nil,
            members: memberDeclBlockSyntax.withLeadingTrivia(.spaces(1))
        )
 
        return CodeBlockItemSyntax { builder in builder.useItem(Syntax(declaration)) }
    }
    
    private func findAllErrors(_ declaration: DeclarationNotation) -> [DeclarationNotation] {
        let nested = declaration.declarations.flatMap{ findAllErrors($0) }
        
        if declaration.identifier == "Error" {
            return [declaration] + nested
        } else {
            return nested
        }
    }
}
