import Foundation
import Stencil
import StencilSwiftKit

final class StencillServiceGenerator {
    
    func generate(objects: [Service], template: String) throws -> String {

        let template = StencilSwiftTemplate(
            templateString: template,
            environment: stencilSwiftEnvironment()
        )
        
        let context = [
          "services": objects
        ]
        
        return try template.render(context)
    }
}
