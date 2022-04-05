import SwiftSyntax

public class ServiceGenerator {
    
    private let responseName: String = "Response"
    
    private let options: Options
    private let serviceFilePath: String
    private let scopeMatcher = ScopeMatcher(threshold: 8) // size of scope name + 1.
    private let nestedTypesScanner = NestedTypesScanner()
    private let templateGenerator = TemplateGenerator()
    
    private let requestParametersTypealiasGenerator = RequestParametersTypealiasGenerator()
    private let requestParametersRequestConverterGenerator = RequestParametersRequestConverterGenerator()
    private let publicInvocationWithQueue = PublicInvocationOnQueueReturningFutureGenerator()
    private let publicInvocationReturingResult = PublicInvocationReturningResultGenerator()
    private let storedPropertiesExtractor = StoredPropertiesExtractor()
    
    
    public init(scope: AccessLevelScope, templatePaths: [String], serviceFilePath: String) {
        options = Options(scope: scope, templatePaths: templatePaths)
        self.serviceFilePath = serviceFilePath
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
    private func matchNested(_ declaration: DeclarationNotation) -> DeclarationNotation? {
        declaration.declarations.first { $0.identifier == "Request" }
    }
    
    private func match(_ declaration: DeclarationNotation) -> ServiceData? {
        if let request = matchNested(declaration),
           let response = matchNested(declaration) {
            return ServiceData(this: declaration, request: request, response: response)
        }
        return nil
    }
    
    private func scan(_ declaration: DeclarationNotation) -> [ServiceData] {
        [match(declaration)].compactMap{ $0 } + declaration.declarations.flatMap(scan)
    }
    
    private func scan(_ node: SourceFileSyntax) -> [ServiceData] {
        nestedTypesScanner.scan(node).flatMap(scan)
    }
}

// MARK: - Private
extension ServiceGenerator: Generator {
    private func generatePublicInvocation(scope: ServiceData, options: Options) -> [DeclSyntax] {
        let structIdentifier = scope.request.fullIdentifier
        let properties = (scope.request.syntax as? StructDeclSyntax).flatMap(self.storedPropertiesExtractor.extract)
        let variables = properties?[structIdentifier]?.1
        let typealiasDeclaration = variables.flatMap({self.requestParametersTypealiasGenerator.with(variables: $0)}).map({$0.generate(.typealias)}).flatMap(DeclSyntax.init).flatMap({$0.withTrailingTrivia(.newlines(1))})
        let converterDeclaration = variables.flatMap({self.requestParametersRequestConverterGenerator.with(variables: $0)}).map({$0.generate(.function)}).flatMap(DeclSyntax.init)
        let publicInvocationWithQueueDeclaration = variables.flatMap({self.publicInvocationWithQueue.with(variables: $0)}).map({$0.generate(.function)}).flatMap(DeclSyntax.init)
        let publicInvocationReturningResultDeclaration = variables.flatMap({self.publicInvocationReturingResult.with(variables: $0)}).map({$0.generate(.function)}).flatMap(DeclSyntax.init)
        let result = [typealiasDeclaration, converterDeclaration, publicInvocationWithQueueDeclaration, publicInvocationReturningResultDeclaration].compactMap({$0})
        return result
    }
    
    private func generateTemplate(options: Options) -> [DeclSyntax] {
        if let result = options.templatePaths.first.flatMap(self.templateGenerator.generate).flatMap(SourceFileSyntax.init) {
            return result.statements.compactMap{$0.item.asProtocol(DeclSyntaxProtocol.self)?._syntaxNode}.compactMap(DeclSyntax.init)
        }
        return []
    }
    
    private func generateService(serviceName: String, scope: ServiceData) -> Syntax {
        let serviceNameIdentifier = SyntaxFactory.makeIdentifier(serviceName)
        
        let memberDeclList: [MemberDeclListItemSyntax] = [
            generatePublicInvocation(scope: scope, options: options),
            generateTemplate(options: options)
        ]
            .flatMap{$0}
            .compactMap(MemberDeclListItemSyntax({_ in}).withDecl)
                                            
        let memberDeclListSyntax = SyntaxFactory.makeMemberDeclList(memberDeclList)
        let memberDeclBlockSyntax = SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.newlines(1)), members: memberDeclListSyntax, rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.newlines(1)).withTrailingTrivia(.newlines(1)))
        
        let enumTokenSyntax = options.scope.token
        
        let enumAttributesListSyntax = SyntaxFactory.makeAttributeList([
            .init(enumTokenSyntax.withTrailingTrivia(.spaces(1)))
        ])
        
        let result = SyntaxFactory.makeEnumDecl(attributes: enumAttributesListSyntax, modifiers: nil, enumKeyword: SyntaxFactory.makeEnumKeyword().withTrailingTrivia(.spaces(1)), identifier: serviceNameIdentifier, genericParameters: nil, inheritanceClause: nil, genericWhereClause: nil, members: memberDeclBlockSyntax)
        return .init(result.withLeadingTrivia(.newlines(1)))
    }
            
    func generate(scope: ServiceData) -> Syntax {
        let scopeName = scope.this.fullIdentifier
        let scopeTypeSyntax = SyntaxFactory.makeTypeIdentifier(scopeName)
        // NOTE: scopeName except first scope. Custom behaviour.
        
        guard let endpoints = RpcServiceFileParser().parse(serviceFilePath),
                let suffix = scopeMatcher.bestRpc(scope: scope, endpoints: endpoints)?.name
        else {
            return .blank
        }
        
        // first, add invocation
        let generator = PrivateInvocationGenerator().with(suffix: suffix)
        let invocationSyntax = generator.generate(.structure).raw()
        
        // next, add service
        let serviceSyntax = generateService(serviceName: "Service", scope: scope)
                    
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
