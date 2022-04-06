import SwiftSyntax

public class InitializerGenerator: Generator {
    public let scope: AccessLevelScope
    
    public init(scope: AccessLevelScope) {
        self.scope = scope
    }

    public func generate(_ node: SourceFileSyntax) -> Syntax {
        let fieldsExtractor = StoredPropertiesExtractor()
        _ = fieldsExtractor.visit(node)
        // we don't care about changing, we only need parsing variables.
        
        var items: [CodeBlockItemSyntax] = []
        
        for (_, fields) in fieldsExtractor.extractedFields.sorted(by: { (lhs, rhs) -> Bool in
            lhs.key < rhs.key
        }) {
            let (structure, storedVariables) = fields
            let variablesNamesAndTypes = storedVariables.map({($0.name, $0.typeAnnotationSyntax?.type)}).filter{$0.1 != nil}
            guard !variablesNamesAndTypes.isEmpty else { continue }

            let functionParameters = variablesNamesAndTypes.compactMap { (name, type) -> FunctionParameterSyntax? in
                guard let type = type else { return nil }
                // TODO: Remove trailingTrivia somehow... type is immutable :(
                let typeName = type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                return FunctionParameterSyntax { b in
                    b.useFirstName(SyntaxFactory.makeIdentifier(name))
                    b.useColon(SyntaxFactory.makeColonToken(trailingTrivia: [.spaces(1)]))
                    b.useType(SyntaxFactory.makeTypeIdentifier(typeName))
                    if name != variablesNamesAndTypes.last?.0 {
                        b.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: [.spaces(1)]))
                    }
                }
            }
            
            let parameters = ParameterClauseSyntax { b in
                b.useLeftParen(SyntaxFactory.makeLeftParenToken())
                for parameter in functionParameters {
                    b.addParameter(parameter)
                }
                b.useRightParen(SyntaxFactory.makeRightParenToken(leadingTrivia: [.spaces(0)], trailingTrivia: [.spaces(0)]))
            }
                                                
            let statements: [CodeBlockItemSyntax] = variablesNamesAndTypes.map{$0.0}.compactMap {
                let list: [CodeBlockItemSyntax] = [
                    CodeBlockItemSyntax.init{_ in }.withItem(.init(SyntaxFactory.makeSelfKeyword())),
                    CodeBlockItemSyntax.init{_ in }.withItem(.init(SyntaxFactory.makePeriodToken())),
                    CodeBlockItemSyntax.init{_ in }.withItem(.init(SyntaxFactory.makeIdentifier($0))),
                    CodeBlockItemSyntax.init{_ in }.withItem(.init(SyntaxFactory.makeAssignmentExpr(assignToken: SyntaxFactory.makeToken(.equal, presence: .present)).withLeadingTrivia([.spaces(1)]).withTrailingTrivia([.spaces(1)]))),
                    CodeBlockItemSyntax.init{_ in }.withItem(.init(SyntaxFactory.makeIdentifier($0))),
                ]
                let codeBlockItemList = SyntaxFactory.makeCodeBlockItemList(list)
                return .init { (b) in b.useItem(.init(codeBlockItemList)) }
            }
            
            let singleLeadingTrivia: Trivia = [.spaces(4)] //[.tabs(1)]
            let doubleLeadingTrivia: Trivia = [.spaces(8)] //[.tabs(2)]
            
            let body = CodeBlockSyntax { b in
                b.useLeftBrace(SyntaxFactory.makeLeftBraceToken().withTrailingTrivia([.newlines(1)]))
                for statement in statements {
                    b.addStatement(statement.withTrailingTrivia([.newlines(1)]).withLeadingTrivia(doubleLeadingTrivia))
                }
                b.useRightBrace(
                    SyntaxFactory.makeRightBraceToken()
                        .withTrailingTrivia([.newlines(1)])
                        .withLeadingTrivia(singleLeadingTrivia)
                )
            }

            let initializerTokenSyntax = SyntaxFactory.makeIdentifier("")
            
            let initializerAttributesListSyntax = SyntaxFactory.makeAttributeList([
                .init(initializerTokenSyntax.withLeadingTrivia(.newlines(1))
                )
            ])
            
            let initializer = SyntaxFactory.makeInitializerDecl(attributes: initializerAttributesListSyntax, modifiers: nil, initKeyword: SyntaxFactory.makeInitKeyword(), optionalMark: nil, genericParameterClause: nil, parameters: parameters.withTrailingTrivia([.spaces(1)]), throwsOrRethrowsKeyword: nil, genericWhereClause: nil, body: body)
            
            let memberDeclList = SyntaxFactory.makeMemberDeclList([
                .init{b in b.useDecl(.init(initializer.withLeadingTrivia(singleLeadingTrivia)))}
            ])
            
            let membersDeclSyntax = SyntaxFactory.makeMemberDeclBlock(
                leftBrace: SyntaxFactory.makeLeftBraceToken(
                    leadingTrivia: [.spaces(1)],
                    trailingTrivia: [.newlines(1)]
                ),
                members: memberDeclList,
                rightBrace: SyntaxFactory.makeRightBraceToken(leadingTrivia: [.newlines(0)])
            )
            
            let extensionTokenSyntax = scope.token
            
            let extensionAttributesListSyntax = SyntaxFactory.makeAttributeList([
                .init(extensionTokenSyntax.withTrailingTrivia(.spaces(1)))
            ])
            
            let extensionDeclSyntax = SyntaxFactory.makeExtensionDecl(
                attributes: extensionAttributesListSyntax,
                modifiers: nil,
                extensionKeyword: SyntaxFactory.makeExtensionKeyword().withTrailingTrivia(.spaces(1)),
                extendedType: structure,
                inheritanceClause: nil,
                genericWhereClause: nil,
                members: membersDeclSyntax
            )
            
            let newItem = SyntaxFactory.makeCodeBlockItem(
                item: .init(extensionDeclSyntax),
                semicolon: nil,
                errorTokens: nil
            )
                .withLeadingTrivia(.newlines(1))
                .withTrailingTrivia(.newlines(1))
            
            items.append(newItem)
        }
        
        if items.isEmpty {
            return .blank
        }
                
        return Syntax(
            SyntaxFactory.makeSourceFile(
                statements: SyntaxFactory.makeCodeBlockItemList(items),
                eofToken: SyntaxFactory.makeToken(.eof, presence: .present)
            )
        )
    }
}
