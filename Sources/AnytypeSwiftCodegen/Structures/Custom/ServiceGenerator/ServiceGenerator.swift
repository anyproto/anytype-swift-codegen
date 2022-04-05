import SwiftSyntax

extension ServiceGenerator {
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
    
    enum ServicePart {
        case publicInvocation(Scope)
        case template
    }
}

extension ServiceGenerator {
    struct Options {
        let serviceName: String = "Service"
        let requestName: String = "Request"
        let responseName: String = "Response"
        let bestMatchThreshold: Int = 8 // size of scope name + 1.
        
        let scope: AccessLevelScope
        let templatePaths: [String]
        let serviceFilePath: String
        
        init(
            scope: AccessLevelScope,
            templatePaths: [String],
            serviceFilePath: String
        ) {
            self.scope = scope
            self.templatePaths = templatePaths
            self.serviceFilePath = serviceFilePath
        }
    }
}

public class ServiceGenerator: SyntaxRewriter {
    
    private let options: Options
    private let scopeMatcher: ScopeMatcher
    private let nestedTypesScanner = NestedTypesScanner()
    private let templateGenerator = TemplateGenerator()
    
    private let requestParametersTypealiasGenerator = RequestParametersTypealiasGenerator()
    private let requestParametersRequestConverterGenerator = RequestParametersRequestConverterGenerator()
    private let publicInvocationWithQueue = PublicInvocationOnQueueReturningFutureGenerator()
    private let publicInvocationReturingResult = PublicInvocationReturningResultGenerator()
    private let storedPropertiesExtractor = StoredPropertiesExtractor()
    
    
    public init(
        scope: AccessLevelScope = AccessLevelScope.public,
        templatePaths: [String] = [],
        serviceFilePath: String = ""
    ) {
        options = Options(
            scope: scope,
            templatePaths: templatePaths,
            serviceFilePath: serviceFilePath
        )
        scopeMatcher = ScopeMatcher(threshold: options.bestMatchThreshold, filePath: serviceFilePath)
    }
    
    override public func visit(_ node: SourceFileSyntax) -> Syntax {
        generate(node)
    }
    
    public func generate(_ node: SourceFileSyntax) -> Syntax {
        let codeBlockItemListSyntax = scan(node)
            .compactMap(generate)
            .compactMap(CodeBlockItemSyntax.init{_ in}.withItem)
        
        let result = SyntaxFactory.makeSourceFile(
            statements: SyntaxFactory.makeCodeBlockItemList(codeBlockItemListSyntax),
            eofToken: SyntaxFactory.makeToken(.eof, presence: .present)
        )
        
        return Syntax(result)
    }
    
    // MARK: Scan
    private func matchNested(_ declaration: DeclarationNotation, identifier: String) -> DeclarationNotation? {
        declaration.declarations.first { $0.identifier == identifier }
    }
    
    private func match(_ declaration: DeclarationNotation) -> Scope? {
        if let request = matchNested(declaration, identifier: options.requestName),
           let response = matchNested(declaration, identifier: options.requestName) {
            return Scope(this: declaration, request: request, response: response)
        }
        return nil
    }
    
    private func scan(_ declaration: DeclarationNotation) -> [Scope] {
        [match(declaration)].compactMap{ $0 } + declaration.declarations.flatMap(scan)
    }
    
    private func scan(_ node: SourceFileSyntax) -> [Scope] {
        nestedTypesScanner.scan(node).flatMap(scan)
    }
}

// MARK: - Private
extension ServiceGenerator: Generator {
    private func generate(servicePart: ServicePart, options: Options) -> [DeclSyntax] {
        switch servicePart {
        case let .publicInvocation(scope):
            let structIdentifier = scope.request.fullIdentifier
            let properties = (scope.request.syntax as? StructDeclSyntax).flatMap(self.storedPropertiesExtractor.extract)
            let variables = properties?[structIdentifier]?.1
            let typealiasDeclaration = variables.flatMap({self.requestParametersTypealiasGenerator.with(variables: $0)}).map({$0.generate(.typealias)}).flatMap(DeclSyntax.init).flatMap({$0.withTrailingTrivia(.newlines(1))})
            let converterDeclaration = variables.flatMap({self.requestParametersRequestConverterGenerator.with(variables: $0)}).map({$0.generate(.function)}).flatMap(DeclSyntax.init)
            let publicInvocationWithQueueDeclaration = variables.flatMap({self.publicInvocationWithQueue.with(variables: $0)}).map({$0.generate(.function)}).flatMap(DeclSyntax.init)
            let publicInvocationReturningResultDeclaration = variables.flatMap({self.publicInvocationReturingResult.with(variables: $0)}).map({$0.generate(.function)}).flatMap(DeclSyntax.init)
            let result = [typealiasDeclaration, converterDeclaration, publicInvocationWithQueueDeclaration, publicInvocationReturningResultDeclaration].compactMap({$0})
            return result
        case .template:
            if let result = options.templatePaths.first.flatMap(self.templateGenerator.generate).flatMap(SourceFileSyntax.init) {
                return result.statements.compactMap{$0.item.asProtocol(DeclSyntaxProtocol.self)?._syntaxNode}.compactMap(DeclSyntax.init)
            }
            return []
        }
    }
    
    private func generate(part: Part, options: Options) -> Syntax {
        switch part {
        case let .service(value):
            let serviceName = value.serviceName
            let serviceNameIdentifier = SyntaxFactory.makeIdentifier(serviceName)
            // our result is enum
            
            // fill enum
            let memberDeclList: [MemberDeclListItemSyntax] = [self.generate(servicePart: .publicInvocation(value.scope), options: options), self.generate(servicePart: .template, options: options)].flatMap{$0}.compactMap(MemberDeclListItemSyntax.init({_ in}).withDecl)
                                                
            let memberDeclListSyntax = SyntaxFactory.makeMemberDeclList(memberDeclList)
            let memberDeclBlockSyntax = SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.newlines(1)), members: memberDeclListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.newlines(1)).withTrailingTrivia(.newlines(1)))
            
            let enumTokenSyntax = options.scope.token
            
            let enumAttributesListSyntax = SyntaxFactory.makeAttributeList([
                .init(enumTokenSyntax.withTrailingTrivia(.spaces(1)))
            ])
            
            let result = SyntaxFactory.makeEnumDecl(attributes: enumAttributesListSyntax, modifiers: nil, enumKeyword: SyntaxFactory.makeEnumKeyword().withTrailingTrivia(.spaces(1)), identifier: serviceNameIdentifier, genericParameters: nil, inheritanceClause: nil, genericWhereClause: nil, members: memberDeclBlockSyntax)
            return .init(result.withLeadingTrivia(.newlines(1)))
            
        case let .scope(value):
            let scopeName = value.scope.this.fullIdentifier
            let scopeTypeSyntax = SyntaxFactory.makeTypeIdentifier(scopeName)
            // NOTE: scopeName except first scope. Custom behaviour.
            
            guard let suffix = scopeMatcher.bestRpc(for: value.scope)?.name else {
                return .init(SyntaxFactory.makeBlankSourceFile())
            }
            
            // if suffix not found, we should return empty syntax.
            
            // first, add invocation
            let generator = PrivateInvocationGenerator().with(suffix: suffix)
            let invocationSyntax = generator.generate(.structure).raw()
            
            // next, add service
            let serviceSyntax = self.generate(part: .service(value), options: self.options)
                        
            // build members
            
            let memberDeclList: [MemberDeclListItemSyntax] = [invocationSyntax, serviceSyntax].compactMap(DeclSyntax.init).compactMap { (value) in
                MemberDeclListItemSyntax.init { (b) in b.useDecl(value) }
            }
            let memberDeclListSyntax = SyntaxFactory.makeMemberDeclList(memberDeclList)
            let memberDeclBlockSyntax = SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.newlines(1)), members: memberDeclListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withTrailingTrivia(.newlines(1)))
            
            let extensionTokenSyntax: TokenSyntax = options.scope.token
            
            let extensionAttributesListSyntax = SyntaxFactory.makeAttributeList([
                .init(extensionTokenSyntax.withTrailingTrivia(.spaces(1)))
            ])
            
            let result = SyntaxFactory.makeExtensionDecl(attributes: extensionAttributesListSyntax, modifiers: nil, extensionKeyword: SyntaxFactory.makeExtensionKeyword().withTrailingTrivia(.spaces(1)), extendedType: scopeTypeSyntax, inheritanceClause: nil, genericWhereClause: nil, members: memberDeclBlockSyntax)
            // and build extension
            return .init(result.withLeadingTrivia(.newlines(1)).withTrailingTrivia(.newlines(1)))
        }
    }
    
    private func generate(scope: Scope) -> Syntax {
        return generate(
            part: .scope(
                .init(
                    serviceName: options.serviceName,
                    scope: scope
                )
            ),
            options: options
        )
    }
}
