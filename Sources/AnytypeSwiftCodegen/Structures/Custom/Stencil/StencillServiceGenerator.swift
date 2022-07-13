import Foundation
import Stencil
import StencilSwiftKit

struct StencillServiceGeneratorObject {
    let type: String
    let invocationName: String
    let requestArguments: [Argument]
}

final class StencillServiceGenerator {
    
    func generate(objects: [StencillServiceGeneratorObject], template: String) throws -> String {

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
