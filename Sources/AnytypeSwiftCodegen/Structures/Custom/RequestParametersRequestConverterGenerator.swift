//
//  RequestParametersRequestConverterGenerator.swift
//  
//
//  Created by Dmitry Lobanov on 27.10.2020.
//

import SwiftSyntax

/*
 private static func request(_ parameters: RequestParameters) -> Request {
    .init(abc: parameters.abc, def: parameters.def)
 }
 */

class RequestParametersRequestConverterGenerator: SyntaxRewriter {
    struct Options {
        var functionName = "request"
        var functionArgumentName = "parameters"
        var functionArgumentType = "RequestParameters"
        var resultType = "Request"
        var simple: Bool = false
    }
    static func convert(_ variables: [StoredPropertiesExtractor.VariableFilter.Variable]) -> [(String, String)] {
        variables.compactMap { entry -> (String, String)? in
            guard let type = entry.typeAnnotationSyntax?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
            let name = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return (name, type)
        }
    }
    
    func with(variables list: [StoredPropertiesExtractor.VariableFilter.Variable]) -> Self {
        self.storedPropertiesList = Self.convert(list)
        return self
    }
    
    func with(propertiesList list: [(String, String)]) -> Self {
        self.storedPropertiesList = list
        return self
    }
    
    var storedPropertiesList: [(String, String)] = [
        ("abc", "String"),
        ("def", "Int")
    ]
    var options: Options = .init()
    convenience init(options: Options, variables: [StoredPropertiesExtractor.VariableFilter.Variable]) {
        self.init(options: options)
        self.storedPropertiesList = Self.convert(variables)
    }
    init(options: Options) {
        self.options = options
    }
    override init() {}
    
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
    func generate(_ part: Part, options: Options) -> PartResult {
        switch part {
        case .initializer:
            if options.simple {
                let simpleVariable = SyntaxFactory.makeVariableExpr(options.functionArgumentName)
                return .initializer(.init(simpleVariable))
            }
            let keywordSyntax = SyntaxFactory.makeInitKeyword()
            let calleeSyntax = SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier(""), declNameArguments: nil)
                                    
            let invocationSyntax = SyntaxFactory.makeMemberAccessExpr(base: .init(calleeSyntax), dot: SyntaxFactory.makePeriodToken(), name: keywordSyntax, declNameArguments: nil)
            
            let functionCallArgumentList =
                self.storedPropertiesList.compactMap{$0.0}.compactMap { name in
                TupleExprElementSyntax.init { b in
                    let parentVariableSyntax = SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier(self.options.functionArgumentName), declNameArguments: nil)
                    let dotIdentifier = SyntaxFactory.makePeriodToken()
                    let nameIdentifier = SyntaxFactory.makeIdentifier(name)
                    let memberAccessSyntax = SyntaxFactory.makeMemberAccessExpr(base: .init(parentVariableSyntax), dot: dotIdentifier, name: nameIdentifier, declNameArguments: nil)
                    b.useLabel(SyntaxFactory.makeIdentifier(name))
                    b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                    b.useExpression(.init(memberAccessSyntax))
                    if name != self.storedPropertiesList.last?.0 {
                        b.useTrailingComma(SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1)))
                    }
                }
            }
            
            let functionCallArgumentListSyntax = SyntaxFactory.makeTupleExprElementList(functionCallArgumentList)
            
            let result =
                SyntaxFactory.makeFunctionCallExpr(calledExpression: .init(invocationSyntax), leftParen: SyntaxFactory.makeLeftParenToken(), argumentList: functionCallArgumentListSyntax, rightParen: SyntaxFactory.makeRightParenToken(), trailingClosure: nil, additionalTrailingClosures: nil)
            return .initializer(.init(result))
                    
        case .function:
            let returnTypeSyntax = SyntaxFactory.makeTypeIdentifier(options.resultType)
            let privateKeyword = SyntaxFactory.makePrivateKeyword()
            let staticKeyword = SyntaxFactory.makeStaticKeyword()
            let functionKeyword = SyntaxFactory.makeFuncKeyword()
            let functionNameSyntax = SyntaxFactory.makeIdentifier(options.functionName)
            let namesAndTypes = [(self.options.functionArgumentName, self.options.functionArgumentType)]
            
            let parametersList: [FunctionParameterSyntax] = namesAndTypes.compactMap { (name, type) in
                FunctionParameterSyntax.init{ b in
                    b.useFirstName(SyntaxFactory.makeWildcardKeyword().withTrailingTrivia(.spaces(1)))
                    b.useSecondName(SyntaxFactory.makeIdentifier(name))
                    b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                    b.useType(SyntaxFactory.makeTypeIdentifier(type))
                    if name != namesAndTypes.last?.0 {
                        b.useTrailingComma(SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1)))
                    }
                }
            }
            
            let parametersListSyntax = SyntaxFactory.makeFunctionParameterList(parametersList)
            
            let parameterClauseSyntax = SyntaxFactory.makeParameterClause(leftParen: SyntaxFactory.makeLeftParenToken(), parameterList: parametersListSyntax, rightParen: SyntaxFactory.makeRightParenToken())
            
            let returnClauseSyntax = SyntaxFactory.makeReturnClause(arrow: SyntaxFactory.makeArrowToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1)), returnType: returnTypeSyntax)
            
            let functionSignatureSyntax = FunctionSignatureSyntax.init{
                b in
                b.useInput(parameterClauseSyntax)
                b.useOutput(returnClauseSyntax)
            }
                        
            let attributesListSyntax = SyntaxFactory.makeAttributeList([
                .init(privateKeyword.withTrailingTrivia(.spaces(1))),
                .init(staticKeyword.withTrailingTrivia(.spaces(1)))
            ])
            
             
            var bodyCodeBlockItemList: [CodeBlockItemSyntax] = []
            if case let .initializer(value) = self.generate(.initializer, options: self.options) {
                bodyCodeBlockItemList = [.init{b in b.useItem(.init(value))}]
            }
            let bodyItemListSyntax = SyntaxFactory.makeCodeBlockItemList(bodyCodeBlockItemList)
            let bodyCodeBlockSyntax = SyntaxFactory.makeCodeBlock(leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.newlines(1)), statements: bodyItemListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.newlines(1)).withTrailingTrivia(.newlines(1)))
            
            let result = SyntaxFactory.makeFunctionDecl(attributes: attributesListSyntax, modifiers: nil, funcKeyword: functionKeyword.withTrailingTrivia(.spaces(1)), identifier: functionNameSyntax, genericParameterClause: nil, signature: functionSignatureSyntax, genericWhereClause: nil, body: bodyCodeBlockSyntax)
            return .function(.init(result))
        }
    }
    func generate(_ part: Part) -> Syntax {
        self.generate(part, options: self.options).raw()
    }
    func generate(_ node: SourceFileSyntax) -> Syntax {
        guard !self.storedPropertiesList.isEmpty else { return .init(node) }
        let result = self.generate(.function, options: self.options).raw()
        return result
    }
}
