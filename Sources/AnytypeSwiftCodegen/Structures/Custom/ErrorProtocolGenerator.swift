import SwiftSyntax
import SwiftSyntaxParser

public class ErrorProtocolGenerator: Generator {
    
    private let stencilGenerator = StencillErrorProtocolGenerator()
    private let template: String
    
    public init(template: String) {
        self.template = template
    }
    
    public func generate(_ node: SourceFileSyntax) throws -> String {
        let objects = NestedTypesScanner().scan(node)
            .flatMap(findAllErrors)
            .map(generateObjects)
        
        return try stencilGenerator.generate(objects: objects, template: template)
    }
    
    // MARK: - Private
    private func generateObjects(_ item: DeclarationNotation) -> ObjectInfo {
        return ObjectInfo(type: item.fullIdentifier, fields: [])
    }
    
    private func findAllErrors(_ declaration: DeclarationNotation) -> [DeclarationNotation] {
        let nested = declaration.declarations.flatMap { findAllErrors($0) }
        
        if declaration.identifier == "Error" {
            return [declaration] + nested
        } else {
            return nested
        }
    }
}
