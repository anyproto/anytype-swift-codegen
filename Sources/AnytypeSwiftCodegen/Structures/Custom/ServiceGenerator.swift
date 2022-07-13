import SwiftSyntax
import SwiftSyntaxParser

public class ServiceGenerator {
    
    private let stencilGenerator = StencillServiceGenerator()
        
    private let scope: AccessLevelScope
    private let template: String
    private let serviceFilePath: String
    
    private let scopeMatcher = ScopeMatcher(threshold: 8) // size of scope name + 1.
    private let nestedTypesScanner = NestedTypesScanner()
    
    private let storedPropertiesExtractor = StoredPropertiesExtractor()
    
    public init(scope: AccessLevelScope, template: String, serviceFilePath: String) {
        self.scope = scope
        self.template = template
        self.serviceFilePath = serviceFilePath
    }
    
    public func generate(_ node: SourceFileSyntax) throws -> String {
        let objects = scan(node).compactMap(mapToObjects(serviceData:))
        return try stencilGenerator.generate(objects: objects, template: template)
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
    
    private func mapToObjects(serviceData: ServiceData) -> StencillServiceGeneratorObject? {
        
        let scopeName = serviceData.this.fullIdentifier
        // NOTE: scopeName except first scope. Custom behaviour.
        
        guard let endpoints = RpcServiceFileParser().parse(serviceFilePath),
                let suffix = scopeMatcher.bestRpc(scope: serviceData, endpoints: endpoints)?.name
        else {
            return nil
        }
        
        let structIdentifier = serviceData.request.fullIdentifier
        let properties = (serviceData.request.syntax as? StructDeclSyntax)
            .flatMap(storedPropertiesExtractor.extract)
        let variables = properties?[structIdentifier]?.1 ?? []
        
        let object = StencillServiceGeneratorObject(
            type: scopeName,
            invocationName: suffix,
            requestArguments: variables.map { Argument.init(from: $0) }
        )
        
        return object
    }
}
