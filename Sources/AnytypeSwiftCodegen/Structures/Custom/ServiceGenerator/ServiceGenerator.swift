import SwiftSyntax

extension ServiceGenerator {    
    struct Scope {
        let this: DeclarationNotation
        let request: DeclarationNotation
        let response: DeclarationNotation
    }
    
    enum Part {
        struct Options {
            let serviceName: String
            let scope: Scope
        }
        
        case service(Options)
        case scope(Options)
    }
    
    enum ServicePart {
        case publicInvocation(Scope)
        case template
    }
}

extension ServiceGenerator {
    struct Options {
        let scope: AccessLevelScope
        let templatePaths: [String]
    }
}

public class ServiceGenerator {
    
    private let serviceName: String = "Service"
    private let requestName: String = "Request"
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
    private func matchNested(_ declaration: DeclarationNotation, identifier: String) -> DeclarationNotation? {
        declaration.declarations.first { $0.identifier == identifier }
    }
    
    private func match(_ declaration: DeclarationNotation) -> Scope? {
        if let request = matchNested(declaration, identifier: requestName),
           let response = matchNested(declaration, identifier: requestName) {
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
            
            let memberDeclList: [MemberDeclListItemSyntax] = [
                generate(servicePart: .publicInvocation(value.scope), options: options),
                generate(servicePart: .template, options: options)
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
            
        case let .scope(value):
            let scopeName = value.scope.this.fullIdentifier
            let scopeTypeSyntax = SyntaxFactory.makeTypeIdentifier(scopeName)
            // NOTE: scopeName except first scope. Custom behaviour.
            
            guard let endpoints = RpcServiceFileParser().parse(serviceFilePath),
                    let suffix = scopeMatcher.bestRpc(scope: value.scope, endpoints: endpoints)?.name
            else {
                return .blank
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
                .init(serviceName: serviceName, scope: scope)
            ),
            options: options
        )
    }
}
