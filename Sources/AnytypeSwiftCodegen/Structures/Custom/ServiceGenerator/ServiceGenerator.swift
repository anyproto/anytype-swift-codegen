import SwiftSyntax

extension ServiceGenerator {
    struct Options {
        let serviceName: String = "Service"
        let requestName: String = "Request"
        let responseName: String = "Response"
        let bestMatchThreshold: Int = 8 // size of scope name + 1.
        let simple: Bool = true
        
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
    
    let options: Options
    let scopeMatcher: ScopeMatcher
    
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
    lazy var requestParametersTypealiasGenerator: RequestParametersTypealiasGenerator = {RequestParametersTypealiasGenerator.init(options: .init(simple: self.options.simple))}()
    lazy var requestParametersRequestConverterGenerator: RequestParametersRequestConverterGenerator = {RequestParametersRequestConverterGenerator.init(options: .init(simple: self.options.simple))}()
    var publicInvocationWithQueue: PublicInvocationOnQueueReturningFutureGenerator = .init()
    var publicInvocationReturingResult: PublicInvocationReturningResultGenerator = .init()
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

extension ServiceGenerator: Generator {
    func generate(servicePart: ServicePart, options: Options) -> [DeclSyntax] {
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
    func generate(scope: Scope) -> Syntax {
        return self.generate(part: .scope(.init(serviceName: self.options.serviceName, scope: scope)), options: self.options)
    }
    public func generate(_ node: SourceFileSyntax) -> Syntax {
        let codeBlockItemListSyntax = self.scan(node).compactMap(self.generate).compactMap(CodeBlockItemSyntax.init{_ in}.withItem)
        let result = SyntaxFactory.makeSourceFile(statements: SyntaxFactory.makeCodeBlockItemList(codeBlockItemListSyntax), eofToken: SyntaxFactory.makeToken(.eof, presence: .present))
        return .init(result)
    }
}
