//
//  PublicInvocationGenerator.swift
//  
//
//  Created by Dmitry Lobanov on 23.01.2020.
//

import SwiftSyntax

/*
 public func invoke(id: String, size: Anytype_Model_Image.Size) -> Future<Response, Error> {
     .init { (completion) in
         completion(self.result(.init(id: id, size: size)))
     }
 }
 */

class PublicInvocationGenerator: SyntaxRewriter {
    struct Options {
        var invocationMethodName = "result"
        var functionName = "invoke"
        var closureVariableName = "promise"
        var resultType: String = "Future<Response, Error>"
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
        case initializer, closureArgument, closure, function
    }
    enum PartResult {
        case initializer(ExprSyntax), closureArgument(ExprSyntax), closure(ExprSyntax), function(Syntax)
        func raw() -> Syntax {
            switch self {
            case let .initializer(value): return .init(value)
            case let .closureArgument(value): return .init(value)
            case let .closure(value): return .init(value)
            case let .function(value): return .init(value)
            }
        }
    }
    
    // MARK: Visits
    override func visit(_ node: SourceFileSyntax) -> Syntax {
        self.generate(node)
    }
}

extension PublicInvocationGenerator: Generator {
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
            
        case .closureArgument:
            let methodName = options.invocationMethodName
            let methodNameSyntax = SyntaxFactory.makeIdentifier(methodName)
            let selfSyntax = SyntaxFactory.makeSelfKeyword()
            let selfCalleeSyntax = SyntaxFactory.makeIdentifierExpr(identifier: selfSyntax, declNameArguments: nil)
            let methodInvocationSyntax = SyntaxFactory.makeMemberAccessExpr(base: .init(selfCalleeSyntax), dot: SyntaxFactory.makePeriodToken(), name: methodNameSyntax, declNameArguments: nil)
            
            var methodFunctionCallArgumentList: [TupleExprElementSyntax] = []
            if case let .initializer(value) = self.generate(.initializer, options: options) {
                methodFunctionCallArgumentList = [.init {b in b.useExpression(.init(value))}]
            }
                        
            let result = SyntaxFactory.makeFunctionCallExpr(calledExpression: .init(methodInvocationSyntax), leftParen: SyntaxFactory.makeLeftParenToken(), argumentList: SyntaxFactory.makeTupleExprElementList(methodFunctionCallArgumentList), rightParen: SyntaxFactory.makeRightParenToken(), trailingClosure: nil, additionalTrailingClosures: nil)
            return .closureArgument(.init(result))
        
        case .closure:
            let argumentName = options.closureVariableName
            let argumentNameSyntax = SyntaxFactory.makeIdentifier(argumentName)
            let argumentNameExprSyntax = SyntaxFactory.makeIdentifierExpr(identifier: argumentNameSyntax, declNameArguments: nil)
            
            var argumentList: [TupleExprElementSyntax] = []
            if case let .closureArgument(value) = self.generate(.closureArgument, options: options) {
                argumentList = [.init {b in b.useExpression(value)}]
            }
            let argumentListSyntax = SyntaxFactory.makeTupleExprElementList(argumentList)
            
            let argumentCallSyntax = SyntaxFactory.makeFunctionCallExpr(calledExpression: .init(argumentNameExprSyntax), leftParen: SyntaxFactory.makeLeftParenToken(), argumentList: argumentListSyntax, rightParen: SyntaxFactory.makeRightParenToken(), trailingClosure: nil, additionalTrailingClosures: nil)
            
            // closure
            let closureParamListSyntax = SyntaxFactory.makeClosureParamList([
                .init {b in b.useName(SyntaxFactory.makeIdentifier(argumentName))}
            ])
            
            let closureSignatureSyntax = SyntaxFactory.makeClosureSignature(capture: nil, input: .init(closureParamListSyntax), throwsTok: nil, output: nil, inTok: SyntaxFactory.makeInKeyword().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1)))
            
            let closureStatementsItemListSyntax = SyntaxFactory.makeCodeBlockItemList([
                .init { b in b.useItem(.init(argumentCallSyntax)) }
            ])
            
            let closureCallSyntax = SyntaxFactory.makeClosureExpr(leftBrace: SyntaxFactory.makeLeftBraceToken(), signature: closureSignatureSyntax, statements: closureStatementsItemListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken())
            
            // now, initializer
            let initializerCalleeSyntax = SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier(""), declNameArguments: nil)
            
            let initializerMemberAccessSyntax = SyntaxFactory.makeMemberAccessExpr(base: .init(initializerCalleeSyntax), dot: SyntaxFactory.makePeriodToken(), name: SyntaxFactory.makeInitKeyword(), declNameArguments: nil)
            let result = SyntaxFactory.makeFunctionCallExpr(calledExpression: .init(initializerMemberAccessSyntax), leftParen: nil, argumentList: SyntaxFactory.makeTupleExprElementList([]), rightParen: nil, trailingClosure: closureCallSyntax, additionalTrailingClosures: nil)
            return .closure(.init(result))
        
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
            if case let .closure(value) = self.generate(.closure, options: options) {
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
