import Foundation
import SwiftSyntax

class RpcServiceFileParser {    
    private let endpointFormat = try! NSRegularExpression(
        pattern: "rpc\\s*(?<name>\\w+)\\s*\\((?<request>[^\\(\\)]+)\\)\\s*returns\\s*\\((?<response>[^\\(\\)]+)\\)"
    )
    
    func parse(_ string: String) -> [Endpoint]? {
        return string
            .split(separator: "\n")
            .map(String.init)
            .compactMap(parseLine)
    }
    
    private func parseLine(_ line: String) -> Endpoint? {
        endpointFormat
            .wholeMatch(string: line)
            .filter{ $0.numberOfRanges >= 3 }
            .map {
                Endpoint(
                    name: line.substring(with: $0.range(withName: "name")),
                    request: line.substring(with: $0.range(withName: "request")),
                    response: line.substring(with: $0.range(withName: "response"))
                )
            }
            .first
    }
}
