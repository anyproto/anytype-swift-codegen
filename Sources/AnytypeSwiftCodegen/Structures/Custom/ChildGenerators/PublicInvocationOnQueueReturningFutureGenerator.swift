//
//  PublicInvocationOnQueueReturningFutureGenerator.swift
//  
//
//  Created by Dmitry Lobanov on 29.10.2020.
//

import SwiftSyntax

/*
 public static func invoke(id: String, size: Anytype_Model_Image.Size, queue: DispatchQueue? = nil) -> Future<Response, Error> {
    self.invoke(parameters: .init(id: id, size: size), on: queue)
 }
 */

class PublicInvocationOnQueueReturningFutureGenerator: SyntaxRewriter {
    struct Options {
        var invocationMethodName = "invoke"
        var functionName = "invoke"
        var functionParameterQueueName = "queue"
        var functionParameterQueueType = "DispatchQueue?"
        var functionParameterQueueDefaultValue = "nil"
        var invocationMethodParametersName = "parameters"
        var invocationMethodQueueName = "on"
        var resultType: String = "Future<Response, Error>"
    }
    
    func with(arguments list: [Argument]) -> Self {
        self.storedPropertiesList = list
        return self
    }
    
    func with(variables list: [Variable]) -> Self {
        self.storedPropertiesList = list.map { Argument.init(from:$0) }
        return self
    }
    
    var storedPropertiesList: [Argument] = []
    var options: Options = .init()
    convenience init(options: Options, variables: [Argument]) {
        self.init(options: options)
        self.storedPropertiesList = variables
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

extension PublicInvocationOnQueueReturningFutureGenerator: Generator {
    func generate(_ part: Part, options: Options) -> PartResult {
        switch part {
        case .initializer:
            let keywordSyntax = SyntaxFactory.makeInitKeyword()
            let calleeSyntax = SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier(""), declNameArguments: nil)
                                    
            let invocationSyntax = SyntaxFactory.makeMemberAccessExpr(base: .init(calleeSyntax), dot: SyntaxFactory.makePeriodToken(), name: keywordSyntax, declNameArguments: nil)
                        
            let functionCallArgumentList =
                self.storedPropertiesList.compactMap { variable in
                TupleExprElementSyntax.init { b in
                    b.useLabel(SyntaxFactory.makeIdentifier(variable.name))
                    b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                    b.useExpression(.init(SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier(variable.name), declNameArguments: nil)))
                    if variable.name != self.storedPropertiesList.last?.name {
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
                    b.useLabel(SyntaxFactory.makeIdentifier(options.invocationMethodParametersName))
                    b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                    b.useExpression(value)
                    b.useTrailingComma(SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1)))
                }
            }
            else {
                parametersTupleExprElementSyntax = .init({ (b) in })
            }
            
            let queueTupleExprElementSyntax: TupleExprElementSyntax = .init { (b) in
                b.useLabel(SyntaxFactory.makeIdentifier(options.invocationMethodQueueName))
                b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                b.useExpression(.init(SyntaxFactory.makeVariableExpr(options.functionParameterQueueName)))
            }
            
            
            let functionCallArgumentSyntax = [parametersTupleExprElementSyntax, queueTupleExprElementSyntax]
            let functionCallListArgumentSyntax = SyntaxFactory.makeTupleExprElementList(functionCallArgumentSyntax)
            
            let calleeName = SyntaxFactory.makeSelfKeyword()
            let invocationMethodName = options.invocationMethodName
            let memberAccessSyntax = SyntaxFactory.makeMemberAccessExpr(base: .init(SyntaxFactory.makeIdentifierExpr(identifier: calleeName, declNameArguments: nil)), dot: SyntaxFactory.makePeriodToken(), name: SyntaxFactory.makeIdentifier(invocationMethodName), declNameArguments: nil)
            let functionInvocationSyntax = SyntaxFactory.makeFunctionCallExpr(calledExpression: .init(memberAccessSyntax), leftParen: SyntaxFactory.makeLeftParenToken(), argumentList: functionCallListArgumentSyntax, rightParen: SyntaxFactory.makeRightParenToken(), trailingClosure: nil, additionalTrailingClosures: nil)
            
            return .invocation(.init(functionInvocationSyntax))
            
        case .function:
            let publicKeyword = SyntaxFactory.makePublicKeyword()
            let staticKeyword = SyntaxFactory.makeStaticKeyword()
            let functionKeyword = SyntaxFactory.makeFuncKeyword()
            let functionNameSyntax = SyntaxFactory.makeIdentifier(options.functionName)
            
            var args = storedPropertiesList
            let queueArg = Argument(
                name: options.functionParameterQueueName,
                type: options.functionParameterQueueType,
                defaultValue: options.functionParameterQueueDefaultValue
            )
            args.append(queueArg)
            
            let functionSignatureSyntax = FunctionSignatureGenerator().generate(args: args, returnType: options.resultType)
                        
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
