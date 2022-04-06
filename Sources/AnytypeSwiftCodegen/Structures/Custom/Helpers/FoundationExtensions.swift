import Foundation

extension NSRegularExpression {
    func wholeMatch(string: String) -> [NSTextCheckingResult] {
        matches(in: string, options: [], range: string.wholeRange)
    }
}

extension String {
    var wholeRange: NSRange {
        NSRange(location: 0, length: count)
    }

    func substring(with range: NSRange) -> String {
        (self as NSString).substring(with: range)
    }
}
