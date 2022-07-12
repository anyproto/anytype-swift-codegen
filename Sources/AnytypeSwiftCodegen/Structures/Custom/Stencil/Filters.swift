import Foundation

enum Filter {
    
    static func removeEmptyLines(_ value: Any?, arguments: [Any?]) throws -> Any? {
        guard let string = value as? String else { return value }
        return string
            .components(separatedBy: .newlines)
            .filter {
                !$0.trimmingCharacters(in: .whitespaces).isEmpty
            }
            .joined(separator: "\n")
    }
    
    static func removeNewlines(_ value: Any?, arguments: [Any?]) throws -> Any? {
        guard let string = value as? String else { return value }
        return string
            .components(separatedBy: .newlines)
            .map(removeLeadingWhitespaces(from:))
            .joined()
            .trimmingCharacters(in: .whitespaces)
    }
    
    static func removeLeadingWhitespaces(from string: String) -> String {
        let chars = string.unicodeScalars.drop { CharacterSet.whitespaces.contains($0) }
        return String(chars)
    }
}
