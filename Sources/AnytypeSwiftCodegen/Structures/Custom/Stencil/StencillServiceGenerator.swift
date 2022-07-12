import Foundation
import Stencil
import StencilSwiftKit

struct StencillServiceGeneratorObject {
    let type: String
    let invocationName: String
    let requestArguments: [Argument]
}

final class StencillServiceGenerator {
    
    func generate(objects: [StencillServiceGeneratorObject]) -> String {
//        let loader = DictionaryLoader(templates: Templates.all)
//        let environment = Environment(loader: loader, extensions: [Extension.default])
        
        let template = StencilSwiftTemplate(
            templateString: StencillServiceGeneratorTemplate,
            environment: stencilSwiftEnvironment()
        )
        
        let context = [
          "endpoints": objects
        ]
        
        do {
            let rendered = try template.render(context)
//            let rendered = try environment.renderTemplate(name: Templates.serviceName, context: context)
            return rendered ?? ""
        } catch {
            print(error)
            return ""
        }
    }
}
