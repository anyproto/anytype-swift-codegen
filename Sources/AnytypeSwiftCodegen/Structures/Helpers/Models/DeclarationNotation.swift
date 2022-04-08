import SwiftSyntax

struct DeclarationNotation: CustomStringConvertible {
    var description: String { output(0) }
    
    func output(_ level: Int) -> String {
        let leading = String(repeating: "\t", count: level)
        let trailing = String(repeating: "\t", count: level)
        
        return leading + "\(identifier)->\n" + declarations.compactMap{$0.output(level + 1)}.joined(separator: "\n") + trailing
    }
    
    var declaration: DeclarationType = .unknown
    var syntax: DeclSyntaxProtocol = SyntaxFactory.makeBlankUnknownDecl()
    var declarations: [DeclarationNotation] = []
    
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
    
    mutating func configured(declarations: [DeclarationNotation]) -> Self {
        self.declarations = declarations
        return self
    }
}
