import SwiftSyntax
import SwiftSyntaxParser

public class ObjectExtensionGenerator: Generator {
    
    private let stencilGenerator = StencilInitializerGenerator()
    
    private let template: String
    
    public init(template: String) {
        self.template = template
    }

    public func generate(_ node: SourceFileSyntax) throws -> String {
        let fieldsExtractor = StoredPropertiesExtractor()
        _ = fieldsExtractor.visit(node)
        // we don't care about changing, we only need parsing variables.
        
        let objects = fieldsExtractor.extractedFields
            .sorted { $0.key < $1.key }
            .map { fields -> ObjectInfo in
                let (_, data) = fields
            
                let fields = data.variables.map { Argument(from: $0) }
                return ObjectInfo(fullType: data.fullIdentifier, type: data.identifier, fields: fields)
            }
        
        return try stencilGenerator.generate(objects: objects, template: template)
    }
}
