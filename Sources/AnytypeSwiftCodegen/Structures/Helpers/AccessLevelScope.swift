import Foundation
import SwiftSyntax

public enum AccessLevelScope {
    case `internal`
    case `public`
    
    var token: TokenSyntax {
        switch self {
        case .internal:
            return SyntaxFactory.makeInternalKeyword()
        case .public:
            return SyntaxFactory.makePublicKeyword()
        }
    }
}
