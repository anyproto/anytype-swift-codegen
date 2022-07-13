import SwiftSyntax

struct DeclarationNotation {
    
    let declaration: DeclarationType
    let syntax: DeclSyntaxProtocol
    let declarations: [DeclarationNotation]
    
    var identifier: String {
        switch self.syntax {
        case let value as StructDeclSyntax:
            return value.identifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
        case let value as EnumDeclSyntax:
            return value.identifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
        default: return ""
        }
    }
    
    var fullIdentifier: String {
        switch syntax {
        case let structSyntax as StructDeclSyntax:
            return structSyntax.fullIdentifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
        case let enumSyntax as EnumDeclSyntax:
            return enumSyntax.fullIdentifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            assertionFailure()
            return ""
        }
    }
}
