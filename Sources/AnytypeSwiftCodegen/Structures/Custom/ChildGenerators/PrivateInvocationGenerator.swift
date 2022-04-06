//
//  PrivateInvocationGenerator.swift
//  
//
//  Created by Dmitry Lobanov on 23.01.2020.
//

import SwiftSyntax

/*
 struct Invocation {
    static func invoke(_ data: Data?) -> Data? {
        Lib.LibImageGetBlob(data)
    }
 }
 */

class PrivateInvocationGenerator: SyntaxRewriter {
    struct Options {
        var callee: String = "Lib" // Lib.methodName
        var prefix: String = "Service" // callee.<Lib>methodName
        var className: String = "Abc.Def" // Lib.LibAbcDef
        var suffix: String = ""
        var name: String = "Invocation"
        var functionName: String = "invoke"
        var parameterName: String = "data"
        var parameterType: String = "Data?"
        var functionReturnType: String = "Data?"
    }
    var options: Options = .init()
    init(options: Options) {
        self.options = options
    }
    override init() {}
    
    func with(suffix: String) -> Self {
        self.options.suffix = suffix
        return self
    }

    enum Part {
        case structure, function, invocation
    }
    
    enum PartResult {
        case structure(Syntax), function(FunctionDeclSyntax), invocation(FunctionCallExprSyntax)
        func raw() -> Syntax {
            switch self {
            case let .structure(value): return value
            case let .function(value): return .init(value)
            case let .invocation(value): return .init(value)
            }
        }
    }
    
    func generate(part: Part, options: Options) -> PartResult {
        switch part {
        case .invocation:
            let calleeName = options.callee
            let parameterName = options.parameterName
            let invocation = options.prefix + options.suffix
            
            let argumentList = SyntaxFactory.makeTupleExprElementList([
                .init({b in b.useExpression(.init(SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier(parameterName), declNameArguments: nil)))})
            ])
                        
            let calleeSyntax = SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier(calleeName), declNameArguments: nil)
            let invocationSyntax = SyntaxFactory.makeMemberAccessExpr(base: .init(calleeSyntax), dot: SyntaxFactory.makePeriodToken(), name: SyntaxFactory.makeIdentifier(invocation), declNameArguments: nil)
            
            let result = SyntaxFactory.makeFunctionCallExpr(calledExpression: .init(invocationSyntax), leftParen: SyntaxFactory.makeLeftParenToken(), argumentList: argumentList, rightParen: SyntaxFactory.makeRightParenToken(), trailingClosure: nil, additionalTrailingClosures: nil)
            return .invocation(result)
            
        case .function:
            let parameterName = options.parameterName
            let parameterType = options.parameterType
            let functionReturnType = options.functionReturnType
            let staticKeywordSyntax = SyntaxFactory.makeStaticKeyword()
            let functionKeywordSyntax = SyntaxFactory.makeToken(.funcKeyword, presence: .present)
            let functionNameSyntax = SyntaxFactory.makeIdentifier(options.functionName)
            let invocationSyntax = self.generate(part: .invocation, options: options).raw()
            let bodySyntax = SyntaxFactory.makeCodeBlockItemList([
                .init {b in b.useItem(invocationSyntax)}
            ])
            let bodyCodeBlockSyntax = SyntaxFactory.makeCodeBlock(leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1)), statements: bodySyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.spaces(1)))
            let functionParameterListSyntax = SyntaxFactory.makeFunctionParameterList([
                .init {b in
                    b.useFirstName(SyntaxFactory.makeWildcardKeyword().withTrailingTrivia(.spaces(1)))
                    b.useSecondName(SyntaxFactory.makeIdentifier(parameterName))
                    b.useType(SyntaxFactory.makeTypeIdentifier(parameterType))
                    b.useColon(SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)))
                }
            ])
            let parameterClauseSyntax = SyntaxFactory.makeParameterClause(leftParen: SyntaxFactory.makeLeftParenToken(), parameterList: functionParameterListSyntax, rightParen: SyntaxFactory.makeRightParenToken())
            let returnClauseSyntax = SyntaxFactory.makeReturnClause(arrow: SyntaxFactory.makeArrowToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1)), returnType: SyntaxFactory.makeTypeIdentifier(functionReturnType))
            let functionSignatureSyntax = SyntaxFactory.makeFunctionSignature(input: parameterClauseSyntax, asyncOrReasyncKeyword: nil, throwsOrRethrowsKeyword: nil, output: returnClauseSyntax)
            
            let attributesListSyntax = SyntaxFactory.makeAttributeList([
                .init(staticKeywordSyntax.withTrailingTrivia(.spaces(1)))
            ])
            let result = SyntaxFactory.makeFunctionDecl(attributes: attributesListSyntax, modifiers: nil, funcKeyword: functionKeywordSyntax.withTrailingTrivia(.spaces(1)), identifier: functionNameSyntax, genericParameterClause: nil, signature: functionSignatureSyntax, genericWhereClause: nil, body: bodyCodeBlockSyntax)
            return .function(result)
            
        case .structure:
            let structKeyword = SyntaxFactory.makeToken(.structKeyword, presence: .present)
            let privateKeyword = SyntaxFactory.makePrivateKeyword()
            let identifierName = options.name
            let identifierSyntax = SyntaxFactory.makeIdentifier(identifierName)
            
            var memberDeclList: [MemberDeclListItemSyntax] = []
            
            if case let .function(value) = self.generate(part: .function, options: options) {
                memberDeclList.append(.init { b in b.useDecl(.init(value)) })
            }
            
            let memberDeclListSyntax = SyntaxFactory.makeMemberDeclList(memberDeclList)
            let memberDeclBlockSyntax = SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken().withTrailingTrivia(.newlines(1)), members: memberDeclListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.newlines(1)).withTrailingTrivia(.newlines(1)))
            let attributesListSyntax = SyntaxFactory.makeAttributeList([
                .init(privateKeyword.withTrailingTrivia(.spaces(1)))
            ])
            let result = SyntaxFactory.makeStructDecl(attributes: attributesListSyntax, modifiers: nil, structKeyword: structKeyword.withTrailingTrivia(.spaces(1)), identifier: identifierSyntax.withTrailingTrivia(.spaces(1)), genericParameterClause: nil, inheritanceClause: nil, genericWhereClause: nil, members: memberDeclBlockSyntax
            )
            return .structure(.init(result))
        }
    }
    
    func generate(_ part: Part) -> PartResult {
        self.generate(part: .structure, options: self.options)
    }
    
    // NOTE: Generators should visit source file syntax and generate syntax based on _their_ context, not on Syntax context.
    override func visit(_ node: SourceFileSyntax) -> Syntax {
        .init(self.generate(node))
    }
}

extension PrivateInvocationGenerator: Generator {
    func generate(_ node: SourceFileSyntax) -> Syntax {
        let syntax = self.generate(part: .structure, options: self.options).raw()
        let result = SyntaxFactory.makeSourceFile(
            statements: SyntaxFactory.makeCodeBlockItemList([
                .init {b in b.useItem(syntax)}
            ]),
            eofToken: SyntaxFactory.makeToken(.eof, presence: .present)
        )
        return .init(result)
    }
}

