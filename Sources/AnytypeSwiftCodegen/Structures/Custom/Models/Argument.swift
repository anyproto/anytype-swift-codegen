import Foundation
import SwiftSyntax

struct Argument {
    let name: String
    let internalName: String?
    let type: String
    let defaultValue: String?
    
    init(name: String, internalName: String? = nil, type: String, defaultValue: String? = nil) {
        self.name = name
        self.internalName = internalName
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
