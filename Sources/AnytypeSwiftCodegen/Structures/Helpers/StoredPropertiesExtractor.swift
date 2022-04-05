import Foundation
import SwiftSyntax

class StoredPropertiesExtractor: SyntaxRewriter {
    struct Options {
        var filterNames: [String] = []
        var allowInconsistentSetter: Bool = false
    }
    
    // MARK: Variables
    var options: Options = .init()
    // StructName -> (Struct, [MemberItem])
    var extractedFields: [String: (TypeSyntax, [Variable])] = [:]
    
    var filter = VariableFilter()
    
    // MARK: Extraction
    func extract(_ node: StructDeclSyntax) -> [String: (TypeSyntax, [Variable])] {
        let syntax = node
        let variables = syntax.members.members.enumerated().compactMap{ $0.element.decl.as(VariableDeclSyntax.self) }.map(self.filter.variable).filter({
            !($0.isEmpty() || $0.computed() || $0.unknownType() || $0.inaccessibleDueToAccessLevel())
        })
                
        let identifier = syntax.fullIdentifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
        self.extractedFields[identifier] = (syntax.fullIdentifier, variables)
        
        return self.extractedFields
    }
    
    // MARK: Visits
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        _ = self.extract(node)
        return super.visit(node)
    }
}
