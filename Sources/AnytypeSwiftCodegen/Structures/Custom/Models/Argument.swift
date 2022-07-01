import Foundation
import SwiftSyntax

struct Argument {
    let name: String
    let type: String
    let defaultValue: String?
    
    init(name: String, type: String, defaultValue: String? = nil) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }
}

extension Argument {
    init(from variable: Variable) {
        self.init(
            name: variable.name,
            type: variable.typeName,
            defaultValue: variable.initializerClauseSyntax?.value.description
        )
    }
}
