import SwiftSyntax
import SwiftSyntaxParser

public class ErrorProtocolGenerator: Generator {
    
    private let stencilGenerator = StencillErrorProtocolGenerator()
    
    public init() { }
    
    public func generate(_ node: SourceFileSyntax) -> Syntax {
        let objects = NestedTypesScanner().scan(node)
            .flatMap(findAllErrors)
            .map(generateObjects)
        
        let result = stencilGenerator.generate(objects: objects)
        let syntax = try? SyntaxParser.parse(source: result)
        return syntax?.asSyntax ?? Syntax.blank
    }
    
    // MARK: - Private
    private func generateObjects(_ item: DeclarationNotation) -> InitializerGeneratorObject {
        return InitializerGeneratorObject(type: item.fullIdentifier, fields: [])
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
