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
        var functionName = "invoke"
        var functionParameterQueueName = "queue"
        var functionParameterQueueType = "DispatchQueue?"
        var functionParameterQueueDefaultValue = "nil"
        var invocationMethodParametersName = "request"
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
            let args = storedPropertiesList.map { CallArgument(parameter: $0.name, value: $0.name)}
            let result = FunctionCallGenerator.generate(methodName: ".init", args: args)
            return .initializer(.init(result))
        
        case .invocation:
            
            var args = [CallArgument]()
        
            if case let .initializer(initCall) = self.generate(.initializer, options: options) {
                args.append(CallArgument(parameter: "parameters", value: initCall))
            }
            
            args.append(CallArgument(
                parameter: options.invocationMethodQueueName,
                value: options.functionParameterQueueName
            ))
            let functionInvocationSyntax = FunctionCallGenerator.generate(methodName: "self.invoke", args: args)
            return .invocation(.init(functionInvocationSyntax))
            
        case .function:
            var args = storedPropertiesList
            let queueArg = Argument(
                name: options.functionParameterQueueName,
                type: options.functionParameterQueueType,
                defaultValue: options.functionParameterQueueDefaultValue
            )
            args.append(queueArg)
            
            var bodyCodeBlockItemList: [CodeBlockItemSyntax] = []
            if case let .invocation(value) = self.generate(.invocation, options: options) {
                bodyCodeBlockItemList = [.init{b in b.useItem(.init(value))}]
            }
            let bodyItemListSyntax = SyntaxFactory.makeCodeBlockItemList(bodyCodeBlockItemList)
            let bodyCodeBlockSyntax = SyntaxFactory.makeCodeBlock(leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.newlines(1)), statements: bodyItemListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.newlines(1)).withTrailingTrivia(.newlines(1)))
            
            let result = FunctionDeclGenerator.generate(
                accessLevel: .publicLevel,
                staticFlag: true,
                name: options.functionName,
                args: args,
                returnType: options.resultType,
                body: bodyCodeBlockSyntax
            )
            
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
