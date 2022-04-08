import SwiftSyntax

extension SyntaxFactory {
    static func makeSourceFile(_ codeBlocks: [CodeBlockItemSyntax]) -> SourceFileSyntax {
        return makeSourceFile(
            statements: makeCodeBlockItemList(codeBlocks),
            eofToken: makeToken(.eof, presence: .present)
        )
    }
    
    static func makeEmptyMember() -> MemberDeclBlockSyntax {
        makeMemberDeclBlock(
            leftBrace: makeLeftBraceToken(),
            members: makeMemberDeclList([]),
            rightBrace: makeRightBraceToken().withTrailingTrivia(.newlines(1))
        )
    }
    
    static func makeTypeInheritanceClause(type: String) -> TypeInheritanceClauseSyntax {
        let type = SyntaxFactory.makeTypeIdentifier("Swift.Error")
        return makeTypeInheritanceClause(
            colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
            inheritedTypeCollection: makeInheritedTypeList([type.asInherited])
        )
    }
    
    static func generateEnheritanceExtension(extendedType: TypeSyntax, inheritedType: String) -> ExtensionDeclSyntax {
        let inheritedSyntax = SyntaxFactory.makeTypeInheritanceClause(type: inheritedType)
            
        return SyntaxFactory.makeExtensionDecl(
            attributes: nil,
            modifiers: nil,
            extensionKeyword: SyntaxFactory.makeExtensionKeyword().withTrailingTrivia(.spaces(1)),
            extendedType: extendedType,
            inheritanceClause: inheritedSyntax,
            genericWhereClause: nil,
            members: SyntaxFactory.makeEmptyMember()
        )
    }
}
