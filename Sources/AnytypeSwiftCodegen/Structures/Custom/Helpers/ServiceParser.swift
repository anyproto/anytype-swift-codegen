import Foundation

extension ServiceParser {
    struct Service {
        struct Endpoint {
            let name: String
            let request: String
            let response: String
        }
        let endpoints: [Endpoint]
    }
}

class ServiceParser {
//  read tokens and extract all rpc services endpoints.
    private let endpointFormat: NSRegularExpression = (try? NSRegularExpression(pattern: "rpc\\s+(?<name>\\w+)\\s+\\((?<request>[^\\(\\)]+)\\)\\s+returns\\s+\\((?<response>[^\\(\\)]+)\\)")) ?? NSRegularExpression()
    private let endpointName = "name"
    private let endpointRequest = "request"
    private let endpointResponse = "response"
    
    private func parse(line: String) -> Service.Endpoint? {
        let length = line.count
        let expectedNumbersOfRanges = 3 // count of NSRegularExpressions.
        
        let result = endpointFormat
            .matches(in: line, options: [], range: NSRange.init(location: 0, length: length))
            .filter{$0.numberOfRanges >= expectedNumbersOfRanges}
            .map {
                ($0.range(withName: endpointName), $0.range(withName: endpointRequest), $0.range(withName: endpointResponse))
            }.map {
                ((line as NSString).substring(with: $0.0), (line as NSString).substring(with: $0.1), (line as NSString).substring(with: $0.2))
            }.map(Service.Endpoint.init)
        
        return result.first
    }
    
    func parse(_ string: String) -> Service {
        let strings = string.split(separator: "\n").map(String.init)
        let endpoints = strings.compactMap(self.parse(line:))
        return Service(endpoints: endpoints)
    }
}
