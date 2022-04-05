import Foundation
import SwiftSyntax

class RpcServiceFileParser {
    private let filePath: String
    private let serviceParser = ServiceParser()
    
    init(filePath: String) {
        self.filePath = filePath
    }
    
    func parse(_ filePath: String) -> ServiceParser.Service? {
        guard FileManager.default.fileExists(atPath: filePath) else { return nil }
        return (try? String(contentsOfFile: filePath)).flatMap(serviceParser.parse)
    }
}
