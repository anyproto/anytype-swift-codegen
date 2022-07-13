import Foundation
import SwiftSyntax

struct Argument {
    let name: String
    let type: String
    let defaultValue: String?
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
