//
//  RequestResponseExtensionGenerator.swift
//  
//
//  Created by Dmitry Lobanov on 24.01.2020.
//

import SwiftSyntax
public class RequestResponseExtensionGenerator: SyntaxRewriter {
    struct Options {
        var serviceName: String = "Service"
        var templatePaths: [String] = []
        var requestName: String = "Request"
        var responseName: String = "Response"
    }
    
    var options: Options = .init()
    init(options: Options) {
        self.options = options
    }
    public override init() {}
    
    public func with(templatePaths: [String]) -> Self {
        self.options.templatePaths = templatePaths
        return self
    }
    
    typealias DeclarationNotation = NestedTypesScanner.DeclarationNotation
    struct Scope {
        var this: DeclarationNotation = .init()
        var request: DeclarationNotation = .init()
        var response: DeclarationNotation = .init()
    }
    
    enum Part {
        struct Options {
            var serviceName: String = ""
            var scope: Scope = .init()
        }
        case service(Options)
        case scope(Options)
    }
    enum PartResult {
        case service(Syntax)
        case scope(Syntax)
        func raw() -> Syntax {
            switch self {
            case let .service(value): return value
            case let .scope(value): return value
            }
        }
    }
    
    var nestedTypesScanner: NestedTypesScanner = .init()
    // TODO: Make later service generator separately.
    var templateGenerator: TemplateGenerator = .init()
    var publicInvocationGenerator: PublicInvocationGenerator = .init()
    var storedPropertiesExtractor: StoredPropertiesExtractor = .init()
    enum ServicePart {
        case publicInvocation(Scope)
        case template
    }
    
    // MARK: Scan
    func matchNested(_ declaration: DeclarationNotation, identifier: String) -> DeclarationNotation? {
        return declaration.declarations.first(where: {$0.identifier == identifier})
    }
    
    func match(_ declaration: DeclarationNotation) -> Scope? {
        if let request = self.matchNested(declaration, identifier: self.options.requestName),
           let response = self.matchNested(declaration, identifier: self.options.requestName) {
            return .init(this: declaration, request: request, response: response)
        }
        return nil
    }
    
    func scan(_ declaration: DeclarationNotation) -> [Scope] {
        [self.match(declaration)].compactMap{$0} + declaration.declarations.flatMap(self.scan)
    }
    
    func scan(_ node: SourceFileSyntax) -> [Scope] {
        let result = self.nestedTypesScanner.scan(node).flatMap(self.scan)
        return result
    }
    
    // MARK: Visits
    override public func visit(_ node: SourceFileSyntax) -> Syntax {
        self.generate(node)
    }
}

extension RequestResponseExtensionGenerator: Generator {
    func generate(servicePart: ServicePart, options: Options) -> [DeclSyntax] {
        switch servicePart {
        case let .publicInvocation(scope):
            let structIdentifier = scope.request.fullIdentifier
            let properties = (scope.request.syntax as? StructDeclSyntax).flatMap(self.storedPropertiesExtractor.extract)
            let variables = properties?[structIdentifier]?.1
            let result = variables.flatMap{self.publicInvocationGenerator.with(variables: $0)}.map{$0.generate(.function)}
            return [result].compactMap{$0 as? DeclSyntax}
        case .template:
            if let result = options.templatePaths.first.flatMap(self.templateGenerator.generate) as? SourceFileSyntax {
                return result.statements.compactMap{$0.item as? DeclSyntax}
            }
            return []
        }
    }
    func generate(part: Part, options: Options) -> Syntax {
        switch part {
        case let .service(value):
            let serviceName = value.serviceName
            let serviceNameIdentifier = SyntaxFactory.makeIdentifier(serviceName)
            // our result is enum
            
            // fill enum
            let memberDeclList: [MemberDeclListItemSyntax] = [self.generate(servicePart: .publicInvocation(value.scope), options: options), self.generate(servicePart: .template, options: options)].flatMap{$0}.compactMap(MemberDeclListItemSyntax.init({_ in}).withDecl)
                                                
            let memberDeclListSyntax = SyntaxFactory.makeMemberDeclList(memberDeclList)
            let memberDeclBlockSyntax = SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.newlines(1)), members: memberDeclListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.newlines(1)).withTrailingTrivia(.newlines(1)))
            
            let result = SyntaxFactory.makeEnumDecl(attributes: nil, modifiers: nil, enumKeyword: SyntaxFactory.makeEnumKeyword().withLeadingTrivia(.newlines(1)).withTrailingTrivia(.spaces(1)), identifier: serviceNameIdentifier, genericParameters: nil, inheritanceClause: nil, genericWhereClause: nil, members: memberDeclBlockSyntax)
            return result
            
        case let .scope(value):
            let scopeName = value.scope.this.fullIdentifier
            let scopeTypeSyntax = SyntaxFactory.makeTypeIdentifier(scopeName)
            // NOTE: scopeName except first scope. Custom behaviour.
            let className = scopeName.split(separator: ".").dropFirst().joined()
            
            // first, add invocation
            let generator = PrivateInvocationGenerator().with(className: className)
            let invocationSyntax = generator.generate(.structure).raw()
            
            // next, add service
            let serviceSyntax = self.generate(part: .service(value), options: self.options)
            
            // build members
            let memberDeclList: [MemberDeclListItemSyntax] = [invocationSyntax, serviceSyntax].compactMap{$0 as? DeclSyntax}.compactMap(MemberDeclListItemSyntax.init({_ in}).withDecl)
            let memberDeclListSyntax = SyntaxFactory.makeMemberDeclList(memberDeclList)
            let memberDeclBlockSyntax = SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.newlines(1)), members: memberDeclListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withTrailingTrivia(.newlines(1)))
            
            let attributesListSyntax = SyntaxFactory.makeAttributeList([
                // TODO: Make it public when extended type will have access level public.
                SyntaxFactory.makeInternalKeyword()//.makePublicKeyword()
                    .withLeadingTrivia(.newlines(1)).withTrailingTrivia(.spaces(1))
            ])
            
            let result = SyntaxFactory.makeExtensionDecl(attributes: attributesListSyntax, modifiers: nil, extensionKeyword: SyntaxFactory.makeExtensionKeyword().withTrailingTrivia(.spaces(1)), extendedType: scopeTypeSyntax, inheritanceClause: nil, genericWhereClause: nil, members: memberDeclBlockSyntax)
            // and build extension
            return result
        }
    }
    func generate(scope: Scope) -> Syntax {
        self.generate(part: .scope(.init(serviceName: self.options.serviceName, scope: scope)), options: self.options)
    }
    public func generate(_ node: SourceFileSyntax) -> Syntax {
        let codeBlockItemListSyntax = self.scan(node).compactMap(self.generate).compactMap(CodeBlockItemSyntax.init{_ in}.withItem)        
        let result = SyntaxFactory.makeSourceFile(statements: SyntaxFactory.makeCodeBlockItemList(codeBlockItemListSyntax), eofToken: SyntaxFactory.makeToken(.eof, presence: .present))
        return result
    }
}
