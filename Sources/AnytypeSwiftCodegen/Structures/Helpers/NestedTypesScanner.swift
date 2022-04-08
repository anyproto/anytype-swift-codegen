import SwiftSyntax


class NestedTypesScanner {
    func scan(_ node: SourceFileSyntax) -> [DeclarationNotation] {
        node.statements.compactMap {
            $0.item.asProtocol(DeclSyntaxProtocol.self)
        }.compactMap(scan)
    }
    
    private func scan(_ declaration: DeclSyntaxProtocol) -> DeclarationNotation? {
        switch declaration {
        case let value as StructDeclSyntax:
            return DeclarationNotation(
                declaration: .structure,
                syntax: value,
                declarations: value.members.members.enumerated().compactMap{$0.element.decl}.compactMap(scan)
            )
            
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
    
    // MARK: - Private
    private func declarationType(for declaration: DeclSyntaxProtocol) -> DeclarationType? {
        switch declaration {
        case is StructDeclSyntax: return .structure
        case is EnumDeclSyntax: return .enumeration
        default: return nil
        }
    }
    
    private func scanEntry(_ declaration: DeclSyntaxProtocol) -> DeclarationNotation? {
        declarationType(for: declaration)
            .flatMap {
                .init(declaration: $0, syntax: declaration, declarations: [])
            }
    }
}
