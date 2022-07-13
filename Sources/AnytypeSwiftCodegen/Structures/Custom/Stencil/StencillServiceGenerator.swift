import Foundation
import Stencil
import StencilSwiftKit

final class StencillServiceGenerator {
    
    func generate(objects: [EndpointInfo], template: String) throws -> String {

        let template = StencilSwiftTemplate(
            templateString: template,
            environment: stencilSwiftEnvironment()
        )
        
        let context = [
          "endpoints": objects
        ]
        
        return try template.render(context)
    }
}
