import Foundation
import Stencil
import StencilSwiftKit

final class StencillErrorProtocolGenerator {
    
    func generate(objects: [ObjectInfo], template: String) throws -> String {
        
        let context = [
          "objects": objects
        ]
        
        let template = StencilSwiftTemplate(
            templateString: template,
            environment: stencilSwiftEnvironment()
        )
        
        return try template.render(context)
    }
}
