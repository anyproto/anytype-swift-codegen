import Foundation
import SwiftSyntax
import SwiftSyntaxParser

class TemplateGenerator: SyntaxRewriter {
    override init() {}
    
    func generate(_ filePath: String) -> Syntax? {
        guard FileManager.default.fileExists(atPath: filePath) else { return nil }
        return try? .init(SyntaxParser.parse(URL(fileURLWithPath: filePath)))
    }
}
