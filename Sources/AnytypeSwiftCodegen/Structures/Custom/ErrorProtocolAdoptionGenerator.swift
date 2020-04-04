//
//  ErrorProtocolAdoptionGenerator.swift
//  
//
//  Created by Dmitry Lobanov on 23.01.2020.
//

import SwiftSyntax

public class ErrorProtocolAdoptionGenerator: SyntaxRewriter {
    struct Options {
        var adopteeIdentifier: String = "Error" // The identifier of a declaration that will adopt Swift.Error protocol
        var adoptedProtocolTypeIdentifier: String = "Swift.Error"
    }
    var options: Options = .init()
    init(options: Options) {
        self.options = options
    }
    public override init() {}
    
    var scanner = NestedTypesScanner()
    typealias DeclarationNotation = NestedTypesScanner.DeclarationNotation
    func match(_ declaration: DeclarationNotation, predicate: String) -> DeclarationNotation? {
        if declaration.identifier == predicate {
            return declaration
        }
        else {
            return nil
        }
    }
    
    func search(_ declaration: DeclarationNotation, predicate: String) -> [DeclarationNotation] {
        [self.match(declaration, predicate: predicate)].compactMap{$0} + declaration.declarations.flatMap{self.search($0, predicate: predicate)}
    }

    func search(_ syntax: DeclSyntaxProtocol) -> [DeclarationNotation] {
        guard let declaration = scanner.scan(syntax) else {
            return []
        }
        let errors = self.search(declaration, predicate: self.options.adopteeIdentifier)
        return errors
    }
        
    override public func visit(_ node: SourceFileSyntax) -> Syntax {
        .init(self.generate(node))
    }
}

extension ErrorProtocolAdoptionGenerator: Generator {
    func generate(_ item: DeclarationNotation) -> ExtensionDeclSyntax {
        let extendedType = item.fullIdentifier
        let extendedTypeSyntax = SyntaxFactory.makeTypeIdentifier(extendedType)
        let inheritanceType = self.options.adoptedProtocolTypeIdentifier
        let inheritanceTypeSyntax = SyntaxFactory.makeTypeIdentifier(inheritanceType)
        let inheritedTypeListSyntax = SyntaxFactory.makeInheritedTypeList([
            .init {b in b.useTypeName(inheritanceTypeSyntax)}
        ])
        let typeInheritanceClauseSyntax = SyntaxFactory.makeTypeInheritanceClause(colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)), inheritedTypeCollection: inheritedTypeListSyntax)
        
        let memberDeclListSyntax = SyntaxFactory.makeMemberDeclList([])
        let memberDeclBlockSyntax = SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken(), members: memberDeclListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withTrailingTrivia(.newlines(1)))
        return SyntaxFactory.makeExtensionDecl(attributes: nil, modifiers: nil, extensionKeyword: SyntaxFactory.makeExtensionKeyword().withTrailingTrivia(.spaces(1)), extendedType: extendedTypeSyntax, inheritanceClause: typeInheritanceClauseSyntax, genericWhereClause: nil, members: memberDeclBlockSyntax.withLeadingTrivia(.spaces(1)))
    }
    public func generate(_ node: SourceFileSyntax) -> Syntax {
        let items = node.statements.compactMap{$0.item.asProtocol(DeclSyntaxProtocol.self)}.compactMap(self.search).flatMap{$0}
        let declarations = items.map(self.generate)
        
        let statements = declarations.map(Syntax.init).compactMap{ value in CodeBlockItemSyntax.init { (b) in b.useItem(value) } }
        
        let result = SyntaxFactory.makeSourceFile(statements: SyntaxFactory.makeCodeBlockItemList(statements), eofToken: SyntaxFactory.makeToken(.eof, presence: .present))
        
        return .init(result)
    }
}
