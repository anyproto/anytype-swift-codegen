import Foundation
import Stencil
import StencilSwiftKit

struct InitializerGeneratorObject {
    let type: String
    let fields: [Argument]
}

final class StencilInitializerGenerator {
    
    func generate(objects: [InitializerGeneratorObject]) -> String {
        
//        let loader = DictionaryLoader(templates: Templates.all)
//        let environment = Environment(loader: loader, extensions: [Extension.default])
        
        let context = [
          "objects": objects
        ]
        
        let template = StencilSwiftTemplate(
            templateString: StencilInitializerGeneratorTemplate,
            environment: stencilSwiftEnvironment()
        )
        
        do {
            let rendered = try template.render(context)
            return rendered
        } catch {
            print(error)
            return ""
        }
        
//        let rendered = try? environment.renderTemplate(name: Templates.initName, context: context)
//        return rendered ?? ""
    }
}


