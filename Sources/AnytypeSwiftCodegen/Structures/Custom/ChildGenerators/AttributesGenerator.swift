import Foundation
import SwiftSyntax

enum AccessLevel {
    case publicLevel
    case privateLevel
}

enum AttributesListGenerator {
    
    static func generate(accessLevel: AccessLevel? = nil, staticFlag: Bool = false) -> AttributeListSyntax {
        
        var syntaxes = [Syntax]()
        
        switch accessLevel {
        case .publicLevel:
            syntaxes.append(.init(SyntaxFactory.makePublicKeyword().withTrailingTrivia(.spaces(1))))
        case .privateLevel:
            syntaxes.append(.init(SyntaxFactory.makePrivateKeyword().withTrailingTrivia(.spaces(1))))
        case nil:
            break
        }
        
        if staticFlag == true {
            syntaxes.append(.init(SyntaxFactory.makeStaticKeyword().withTrailingTrivia(.spaces(1))))
        }
        
        return SyntaxFactory.makeAttributeList(syntaxes)
    }
}
