import SwiftSyntax

public class ErrorProtocolAdoptionGenerator: Generator {    
    private let adoptedProtocolTypeIdentifier: String = "Swift.Error"
    private let scanner = NestedTypesScanner()
    
    public init() { }
    
    public func generate(_ node: SourceFileSyntax) -> Syntax {
        let statements = node.statements
            .compactMap{ $0.item.asProtocol(DeclSyntaxProtocol.self) }
            .compactMap(search)
            .flatMap{$0}
            .map(generate)
            .map(Syntax.init)
            .compactMap { syntax in
                CodeBlockItemSyntax { builder in builder.useItem(syntax) }
            }
        
        let result = SyntaxFactory
            .makeSourceFile(
                statements: SyntaxFactory.makeCodeBlockItemList(statements),
                eofToken: SyntaxFactory.makeToken(.eof, presence: .present)
            )
        
        return Syntax(result)
    }
    
    // MARK: - Private
    private func generate(_ item: DeclarationNotation) -> ExtensionDeclSyntax {
        let extendedType = item.fullIdentifier
        let extendedTypeSyntax = SyntaxFactory.makeTypeIdentifier(extendedType)
        let inheritanceType = adoptedProtocolTypeIdentifier
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
        return SyntaxFactory.makeExtensionDecl(
            attributes: nil,
            modifiers: nil,
            extensionKeyword: SyntaxFactory.makeExtensionKeyword().withTrailingTrivia(.spaces(1)),
            extendedType: extendedTypeSyntax,
            inheritanceClause: typeInheritanceClauseSyntax,
            genericWhereClause: nil,
            members: memberDeclBlockSyntax.withLeadingTrivia(.spaces(1))
        )
    }
    
    private func match(_ declaration: DeclarationNotation) -> DeclarationNotation? {
        if declaration.identifier == "Error" {
            return declaration
        }
        else {
            return nil
        }
    }
    
    private func search(_ declaration: DeclarationNotation) -> [DeclarationNotation] {
        let a = [ match(declaration) ].compactMap{$0}
        let b = declaration.declarations.flatMap{ search($0) }
        
        return a + b
    }

    private func search(_ syntax: DeclSyntaxProtocol) -> [DeclarationNotation] {
        guard let declaration = scanner.scan(syntax) else { return [] }
        
        return search(declaration)
    }
}
