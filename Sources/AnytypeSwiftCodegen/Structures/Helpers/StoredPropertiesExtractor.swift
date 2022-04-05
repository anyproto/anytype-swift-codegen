import Foundation
import SwiftSyntax

class StoredPropertiesExtractor: SyntaxRewriter {
    // StructName -> (Struct, [MemberItem])
    var extractedFields: [String: (TypeSyntax, [Variable])] = [:]
    
    var filter = VariableFilter()
    
    // MARK: Extraction
    func extract(_ node: StructDeclSyntax) -> [String: (TypeSyntax, [Variable])] {
        let variables = node.members.members.enumerated()
            .compactMap{
                $0.element.decl.as(VariableDeclSyntax.self)
            }.map {
                filter.variable($0)
            }.filter {
                !($0.isEmpty || $0.computed || $0.unknownType || $0.inaccessibleDueToAccessLevel())
            }
                
        let identifier = node.fullIdentifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
        extractedFields[identifier] = (node.fullIdentifier, variables)
        
        return extractedFields
    }
    
    // MARK: Visits
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        _ = self.extract(node)
        return super.visit(node)
    }
}
