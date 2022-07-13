import SwiftSyntax
import SwiftSyntaxParser

public class ServiceGenerator {
    
    private let stencilGenerator = StencillServiceGenerator()
        
    private let template: String
    private let serviceProtobuf: String
    
    private let scopeMatcher = ScopeMatcher(threshold: 8) // size of scope name + 1.
    private let nestedTypesScanner = NestedTypesScanner()
    
    private let storedPropertiesExtractor = StoredPropertiesExtractor()
    
    public init(template: String, serviceProtobuf: String) {
        self.template = template
        self.serviceProtobuf = serviceProtobuf
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
    
    private func mapToObjects(serviceData: ServiceData) -> EndpointInfo? {
        
        let scopeName = serviceData.this.fullIdentifier
        // NOTE: scopeName except first scope. Custom behaviour.
        
        guard let endpoints = RpcServiceFileParser().parse(serviceProtobuf),
                let suffix = scopeMatcher.bestRpc(scope: serviceData, endpoints: endpoints)?.name
        else {
            return nil
        }
        
        let structIdentifier = serviceData.request.fullIdentifier
        let properties = (serviceData.request.syntax as? StructDeclSyntax)
            .flatMap(storedPropertiesExtractor.extract)
        let variables = properties?[structIdentifier]?.variables ?? []
        
        let object = EndpointInfo(
            type: scopeName,
            invocationName: suffix,
            requestArguments: variables.map { Argument.init(from: $0) }
        )
        
        return object
    }
}
