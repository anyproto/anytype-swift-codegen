import Foundation
import Stencil
import StencilSwiftKit

struct InitializerGeneratorObject {
    let type: String
    let fields: [Argument]
}

final class StencilInitializerGenerator {
    
    func generate(objects: [InitializerGeneratorObject], template: String) throws -> String {
        
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


