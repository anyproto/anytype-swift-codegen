//
//  PublicInvocationReturningResultGenerator.swift
//  
//
//  Created by Dmitry Lobanov on 08.02.2021.
//

import SwiftSyntax

/*
 public static func invoke(id: String, size: Anytype_Model_Image.Size) -> Result<Response, Error> {
 self.result(.init(id: id, size: size))
 }
 */

class PublicInvocationReturningResultGenerator: SyntaxRewriter {
    /// TODO: Fix names later.
    /// InvocationMethodName means "outerFunction" and functionName means inner function.
    struct Options {
        var invocationMethodName = "result"
        var functionName = "invoke"
        var resultType: String = "Result<Response, Error>"
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
    
    var storedPropertiesList: [(String, String)] = []
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
        case initializer, invocation, function
    }
    enum PartResult {
        case initializer(ExprSyntax), invocation(ExprSyntax), function(Syntax)
        func raw() -> Syntax {
            switch self {
            case let .initializer(value): return .init(value)
            case let .invocation(value): return .init(value)
            case let .function(value): return .init(value)
            }
        }
    }
    
    // MARK: Visits
    override func visit(_ node: SourceFileSyntax) -> Syntax {
        self.generate(node)
    }
}

extension PublicInvocationReturningResultGenerator: Generator {
    func generate(_ part: Part, options: Options) -> PartResult {
        switch part {
        case .initializer:
            let keywordSyntax = SyntaxFactory.makeInitKeyword()
            let calleeSyntax = SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier(""), declNameArguments: nil)
            
            let invocationSyntax = SyntaxFactory.makeMemberAccessExpr(base: .init(calleeSyntax), dot: SyntaxFactory.makePeriodToken(), name: keywordSyntax, declNameArguments: nil)
            
            let functionCallArgumentList =
                self.storedPropertiesList.compactMap{$0.0}.compactMap { name in
                    TupleExprElementSyntax.init { b in
                        b.useLabel(SyntaxFactory.makeIdentifier(name))
                        b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                        b.useExpression(.init(SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier(name), declNameArguments: nil)))
                        if name != self.storedPropertiesList.last?.0 {
                            b.useTrailingComma(SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1)))
                        }
                    }
                }
            
            let functionCallArgumentListSyntax = SyntaxFactory.makeTupleExprElementList(functionCallArgumentList)
            
            let result =
                SyntaxFactory.makeFunctionCallExpr(calledExpression: .init(invocationSyntax), leftParen: SyntaxFactory.makeLeftParenToken(), argumentList: functionCallArgumentListSyntax, rightParen: SyntaxFactory.makeRightParenToken(), trailingClosure: nil, additionalTrailingClosures: nil)
            return .initializer(.init(result))
            
        case .invocation:
            
            let parametersTupleExprElementSyntax: TupleExprElementSyntax
            if case let .initializer(value) = self.generate(.initializer, options: options) {
                parametersTupleExprElementSyntax = .init { (b) in
                    b.useExpression(value)
                }
            }
            else {
                parametersTupleExprElementSyntax = .init({ (b) in })
            }
                        
            let functionCallArgumentSyntax = [parametersTupleExprElementSyntax]
            let functionCallListArgumentSyntax = SyntaxFactory.makeTupleExprElementList(functionCallArgumentSyntax)
            
            let calleeName = SyntaxFactory.makeSelfKeyword()
            let invocationMethodName = options.invocationMethodName
            let memberAccessSyntax = SyntaxFactory.makeMemberAccessExpr(base: .init(SyntaxFactory.makeIdentifierExpr(identifier: calleeName, declNameArguments: nil)), dot: SyntaxFactory.makePeriodToken(), name: SyntaxFactory.makeIdentifier(invocationMethodName), declNameArguments: nil)
            let functionInvocationSyntax = SyntaxFactory.makeFunctionCallExpr(calledExpression: .init(memberAccessSyntax), leftParen: SyntaxFactory.makeLeftParenToken(), argumentList: functionCallListArgumentSyntax, rightParen: SyntaxFactory.makeRightParenToken(), trailingClosure: nil, additionalTrailingClosures: nil)
            
            return .invocation(.init(functionInvocationSyntax))
            
        case .function:
            let returnTypeSyntax = SyntaxFactory.makeTypeIdentifier(options.resultType)
            let publicKeyword = SyntaxFactory.makePublicKeyword()
            let staticKeyword = SyntaxFactory.makeStaticKeyword()
            let functionKeyword = SyntaxFactory.makeFuncKeyword()
            let functionNameSyntax = SyntaxFactory.makeIdentifier(options.functionName)
            let namesAndTypes = self.storedPropertiesList
                        
            let parameterList: [FunctionParameterSyntax] = namesAndTypes.compactMap { (name, type) in
                FunctionParameterSyntax.init{ b in
                    b.useFirstName(SyntaxFactory.makeIdentifier(name))
                    b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                    b.useType(SyntaxFactory.makeTypeIdentifier(type))
                    if name != namesAndTypes.last?.0 {
                        b.useTrailingComma(SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1)))
                    }
                }
            }
            
            let parametersListSyntax = SyntaxFactory.makeFunctionParameterList(parameterList)
            
            let parameterClauseSyntax = SyntaxFactory.makeParameterClause(leftParen: SyntaxFactory.makeLeftParenToken(), parameterList: parametersListSyntax, rightParen: SyntaxFactory.makeRightParenToken())
            
            let returnClauseSyntax = SyntaxFactory.makeReturnClause(arrow: SyntaxFactory.makeArrowToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1)), returnType: returnTypeSyntax)
            
            let functionSignatureSyntax = FunctionSignatureSyntax.init{
                b in
                b.useInput(parameterClauseSyntax)
                b.useOutput(returnClauseSyntax)
            }
            
            let attributesListSyntax = SyntaxFactory.makeAttributeList([
                .init(publicKeyword.withTrailingTrivia(.spaces(1))),
                .init(staticKeyword.withTrailingTrivia(.spaces(1)))
            ])
            
            
            var bodyCodeBlockItemList: [CodeBlockItemSyntax] = []
            if case let .invocation(value) = self.generate(.invocation, options: options) {
                bodyCodeBlockItemList = [.init{b in b.useItem(.init(value))}]
            }
            let bodyItemListSyntax = SyntaxFactory.makeCodeBlockItemList(bodyCodeBlockItemList)
            let bodyCodeBlockSyntax = SyntaxFactory.makeCodeBlock(leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.newlines(1)), statements: bodyItemListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.newlines(1)).withTrailingTrivia(.newlines(1)))
            
            let result = SyntaxFactory.makeFunctionDecl(attributes: attributesListSyntax, modifiers: nil, funcKeyword: functionKeyword.withTrailingTrivia(.spaces(1)), identifier: functionNameSyntax, genericParameterClause: nil, signature: functionSignatureSyntax, genericWhereClause: nil, body: bodyCodeBlockSyntax)
            return .function(.init(result))
        }
    }
    func generate(_ part: Part) -> Syntax {
        self.generate(.function, options: self.options).raw()
    }
    func generate(_ node: SourceFileSyntax) -> Syntax {
        guard !self.storedPropertiesList.isEmpty else { return .init(node) }
        let result = self.generate(.function, options: self.options).raw()
        return result
    }
}
