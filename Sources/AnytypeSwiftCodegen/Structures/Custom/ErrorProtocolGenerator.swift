import SwiftSyntax

public class ErrorProtocolGenerator: Generator {
    public init() { }
    
    public func generate(_ node: SourceFileSyntax) -> Syntax {
        let statements = NestedTypesScanner().scan(node)
            .flatMap(findAllErrors)
            .map(generateEnheritanceExtension)
        
        return SyntaxFactory.makeSourceFile(statements).asSyntax
    }
    
    // MARK: - Private
    private func generateEnheritanceExtension(_ item: DeclarationNotation) -> CodeBlockItemSyntax {
        let extendedType = SyntaxFactory.makeTypeIdentifier(item.fullIdentifier)
            
        return SyntaxFactory
            .generateEnheritanceExtension(extendedType: extendedType, inheritedType: "Swift.Error")
            .asCode
    }
    
    private func findAllErrors(_ declaration: DeclarationNotation) -> [DeclarationNotation] {
        let nested = declaration.declarations.flatMap { findAllErrors($0) }
        
        if declaration.identifier == "Error" {
            return [declaration] + nested
        } else {
            return nested
        }
    }
}
