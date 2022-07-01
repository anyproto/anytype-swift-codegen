import SwiftSyntax

class RequestParametersRequestConverterGenerator: SyntaxRewriter {
    let functionName = "request"
    let functionArgumentName = "parameters"
    let functionArgumentType = "RequestParameters"
    let resultType = "Request"

    // for tests
    var storedPropertiesList: [(String, String)] = [
        ("abc", "String"),
        ("def", "Int")
    ]
    
    static func convert(_ variables: [Variable]) -> [(String, String)] {
        variables.compactMap { entry -> (String, String)? in
            let type = entry.typeName
            let name = entry.name
            return (name, type)
        }
    }
    
    func with(variables list: [Variable]) -> Self {
        self.storedPropertiesList = Self.convert(list)
        return self
    }
    
    func with(propertiesList list: [(String, String)]) -> Self {
        self.storedPropertiesList = list
        return self
    }

    enum Part {
        case initializer,//, closureArgument, closure,
             function
    }
    enum PartResult {
        case initializer(ExprSyntax),//, closureArgument(ExprSyntax), closure(ExprSyntax),
        function(Syntax)
        func raw() -> Syntax {
            switch self {
            case let .initializer(value): return .init(value)
//            case let .closureArgument(value): return .init(value)
//            case let .closure(value): return .init(value)
            case let .function(value): return .init(value)
            }
        }
    }
    
    // MARK: Visits
    override func visit(_ node: SourceFileSyntax) -> Syntax {
        self.generate(node)
    }
}

extension RequestParametersRequestConverterGenerator: Generator {
    func generate(_ part: Part) -> PartResult {
        switch part {
        case .initializer:
            let simpleVariable = SyntaxFactory.makeVariableExpr(functionArgumentName)
            return .initializer(.init(simpleVariable))
                    
        case .function:
            let privateKeyword = SyntaxFactory.makePrivateKeyword()
            let staticKeyword = SyntaxFactory.makeStaticKeyword()
            let functionKeyword = SyntaxFactory.makeFuncKeyword()
            let functionNameSyntax = SyntaxFactory.makeIdentifier(functionName)
            
            let args = [
                Argument(
                    name: SyntaxFactory.makeWildcardKeyword().description,
                    internalName: functionArgumentName,
                    type: functionArgumentType
                )
            ]

            let functionSignatureSyntax = FunctionSignatureGenerator().generate(args: args, returnType: resultType)
                        
            let attributesListSyntax = SyntaxFactory.makeAttributeList([
                .init(privateKeyword.withTrailingTrivia(.spaces(1))),
                .init(staticKeyword.withTrailingTrivia(.spaces(1)))
            ])
            
            var bodyCodeBlockItemList: [CodeBlockItemSyntax] = []
            if case let .initializer(value) = generate(.initializer) {
                bodyCodeBlockItemList = [.init{b in b.useItem(.init(value))}]
            }
            let bodyItemListSyntax = SyntaxFactory.makeCodeBlockItemList(bodyCodeBlockItemList)
            let bodyCodeBlockSyntax = SyntaxFactory.makeCodeBlock(leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.newlines(1)), statements: bodyItemListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.newlines(1)).withTrailingTrivia(.newlines(1)))
            
            let result = SyntaxFactory.makeFunctionDecl(attributes: attributesListSyntax, modifiers: nil, funcKeyword: functionKeyword.withTrailingTrivia(.spaces(1)), identifier: functionNameSyntax, genericParameterClause: nil, signature: functionSignatureSyntax, genericWhereClause: nil, body: bodyCodeBlockSyntax)
            return .function(.init(result))
        }
    }
    func generate(_ part: Part) -> Syntax {
        self.generate(part).raw()
    }
    func generate(_ node: SourceFileSyntax) -> Syntax {
        guard !self.storedPropertiesList.isEmpty else { return .init(node) }
        let result = self.generate(.function).raw()
        return result
    }
}
