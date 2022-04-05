import SwiftSyntax

public class ErrorProtocolAdoptionGenerator: SyntaxRewriter {
    typealias DeclarationNotation = NestedTypesScanner.DeclarationNotation
    
    private let adopteeIdentifier: String = "Error"
    private let adoptedProtocolTypeIdentifier: String = "Swift.Error"
    private let scanner = NestedTypesScanner()
    
    override public func visit(_ node: SourceFileSyntax) -> Syntax {
        Syntax(generate(node))
    }
    
    private func match(_ declaration: DeclarationNotation, predicate: String) -> DeclarationNotation? {
        if declaration.identifier == predicate {
            return declaration
        }
        else {
            return nil
        }
    }
    
    private func search(_ declaration: DeclarationNotation, predicate: String) -> [DeclarationNotation] {
        [self.match(declaration, predicate: predicate)].compactMap{$0} + declaration.declarations.flatMap{self.search($0, predicate: predicate)}
    }

    private func search(_ syntax: DeclSyntaxProtocol) -> [DeclarationNotation] {
        guard let declaration = scanner.scan(syntax) else {
            return []
        }
        let errors = self.search(declaration, predicate: adopteeIdentifier)
        return errors
    }
}

extension ErrorProtocolAdoptionGenerator: Generator {
    public func generate(_ node: SourceFileSyntax) -> Syntax {
        let items = node.statements
            .compactMap{ $0.item.asProtocol(DeclSyntaxProtocol.self) }
            .compactMap(self.search)
            .flatMap{$0}
        let declarations = items.map(generate)
        
        let statements = declarations
            .map(Syntax.init)
            .compactMap{
                value in CodeBlockItemSyntax.init { (b) in b.useItem(value) }
            }
        
        let result = SyntaxFactory
            .makeSourceFile(
                statements: SyntaxFactory.makeCodeBlockItemList(statements),
                eofToken: SyntaxFactory.makeToken(.eof, presence: .present)
            )
        
        return Syntax(result)
    }
    
    private func generate(_ item: DeclarationNotation) -> ExtensionDeclSyntax {
        let extendedType = item.fullIdentifier
        let extendedTypeSyntax = SyntaxFactory.makeTypeIdentifier(extendedType)
        let inheritanceType = adoptedProtocolTypeIdentifier
        let inheritanceTypeSyntax = SyntaxFactory.makeTypeIdentifier(inheritanceType)
        let inheritedTypeListSyntax = SyntaxFactory.makeInheritedTypeList([
            .init {b in b.useTypeName(inheritanceTypeSyntax)}
        ])
        let typeInheritanceClauseSyntax = SyntaxFactory.makeTypeInheritanceClause(colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)), inheritedTypeCollection: inheritedTypeListSyntax)
        
        let memberDeclListSyntax = SyntaxFactory.makeMemberDeclList([])
        let memberDeclBlockSyntax = SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken(), members: memberDeclListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withTrailingTrivia(.newlines(1)))
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
}
