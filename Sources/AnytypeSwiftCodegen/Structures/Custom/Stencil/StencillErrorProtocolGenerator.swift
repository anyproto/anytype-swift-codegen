import Foundation
import Stencil
import StencilSwiftKit

final class StencillErrorProtocolGenerator {
    
    func generate(objects: [InitializerGeneratorObject]) -> String {
        
        let context = [
          "objects": objects
        ]
        
        let template = StencilSwiftTemplate(
            templateString: StencillErrorProtocolGeneratorTemplate,
            environment: stencilSwiftEnvironment()
        )
        
        do {
            let rendered = try template.render(context)
            return rendered
        } catch {
            print(error)
            return ""
        }
        
//        let loader = DictionaryLoader(templates: Templates.all)
//        let environment = Environment(loader: loader, extensions: [Extension.default])
//
//        let context = [
//          "objects": objects
//        ]
        
//        let rendered = try? environment.renderTemplate(name: Templates.errorName, context: context)
//        return rendered ?? ""
    }
}
