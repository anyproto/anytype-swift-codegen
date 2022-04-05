import SwiftSyntax

enum DeclarationType: String, CustomStringConvertible {
    case unknown
    case enumeration
    case structure
    
    var description: String { return self.rawValue }
}

extension NestedTypesScanner {
    struct DeclarationNotation: CustomStringConvertible {
        var description: String {
            output(0)
        }
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
            switch self.syntax {
            case let value as StructDeclSyntax:
                return value.fullIdentifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
            case let value as EnumDeclSyntax:
                return value.fullIdentifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
            default:
                return ""
            }
        }
        mutating func configured(declarations: [DeclarationNotation]) -> Self {
            self.declarations = declarations
            return self
        }
    }
}

class NestedTypesScanner: SyntaxRewriter {
    
    func scan(_ node: SourceFileSyntax) -> [DeclarationNotation] {
        node.statements.compactMap {
            $0.item.asProtocol(DeclSyntaxProtocol.self)
        }.compactMap(scan)
    }
    
    func scan(_ declaration: DeclSyntaxProtocol) -> DeclarationNotation? {
        switch declaration {
        case let value as StructDeclSyntax:
            return .init(declaration: .structure, syntax: value, declarations: value.members.members.enumerated().compactMap{$0.element.decl}.compactMap(scan))
            
        case let value as EnumDeclSyntax:
            return .init(declaration: .enumeration, syntax: value, declarations: value.members.members.enumerated().compactMap{$0.element.decl}.compactMap(scan))
            
        case let value as DeclSyntax:
            if let newValue = StructDeclSyntax(.init(value)) {
                return scan(newValue)
            }
            else if let newValue = EnumDeclSyntax(.init(value)) {
                return scan(newValue)
            }
            return nil
            
        default:
            return nil
        }
    }
    
    // MARK: Visits
    override func visit(_ node: SourceFileSyntax) -> Syntax {
        _ = self.scan(node)
        return .init(node)
    }
    
    // MARK: - Private
    private func declarationType(for declaration: DeclSyntaxProtocol) -> DeclarationType? {
        switch declaration {
        case is StructDeclSyntax: return .structure
        case is EnumDeclSyntax: return .enumeration
        default: return nil
        }
    }
    
    private func scanEntry(_ declaration: DeclSyntaxProtocol) -> DeclarationNotation? {
        declarationType(for: declaration).flatMap({.init(declaration: $0, syntax: declaration, declarations: [])})
    }
}
