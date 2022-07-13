import Foundation
import SwiftSyntax

struct StoredPropertiesExtractorResult {
    let fullIdentifier: String
    let identifier: String
    let syntax: TypeSyntax
    let variables: [Variable]
}

class StoredPropertiesExtractor: SyntaxRewriter {
    
    var extractedFields: [String: StoredPropertiesExtractorResult] = [:]
    
    var filter = VariableFilter()
    
    // MARK: Extraction
    func extract(_ node: StructDeclSyntax) -> [String: StoredPropertiesExtractorResult] {
        let variables = node.members.members.enumerated()
            .compactMap {
                $0.element.decl.as(VariableDeclSyntax.self)
            }.compactMap {
                filter.variable($0)
            }.filter {
                !($0.computed || $0.inaccessibleDueToAccessLevel())
            }
        
        let result = StoredPropertiesExtractorResult(
            fullIdentifier: node.fullIdentifier.description.trimmingCharacters(in: .whitespacesAndNewlines),
            identifier: node.identifier.description.trimmingCharacters(in: .whitespacesAndNewlines),
            syntax: node.fullIdentifier,
            variables: variables
        )
                
        extractedFields[result.fullIdentifier] = result
        return extractedFields
    }
    
    // MARK: Visits
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        _ = self.extract(node)
        return super.visit(node)
    }
}
